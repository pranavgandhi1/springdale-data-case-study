with bounds as (
    select
        min(created_date) as min_date,
        max(coalesce(closed_date, created_date)) as max_date
    from {{ ref('fct_tickets') }}
),

spine as (
    select
        dateadd('day', seq4(), b.min_date)::date as day_date
    from table(generator(rowcount => 5000))
    cross join bounds b
    where dateadd('day', seq4(), b.min_date)::date <= b.max_date
),

created as (
    select created_date as day_date, count(*) as tickets_created
    from {{ ref('fct_tickets') }}
    group by 1
),

closed as (
    select closed_date as day_date, count(*) as tickets_closed
    from {{ ref('fct_tickets') }}
    where closed_date is not null
    group by 1
),

joined as (
    select
        s.day_date,
        coalesce(c.tickets_created, 0) as tickets_created,
        coalesce(cl.tickets_closed, 0) as tickets_closed,
        coalesce(c.tickets_created, 0) - coalesce(cl.tickets_closed, 0) as net_change
    from spine s
    left join created c   on s.day_date = c.day_date
    left join closed cl   on s.day_date = cl.day_date
)

select
    day_date,
    tickets_created,
    tickets_closed,
    net_change,
    sum(net_change) over (order by day_date rows between unbounded preceding and current row) as cumulative_backlog
from joined
order by day_date
