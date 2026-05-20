{# Override dbt's default schema naming so custom schemas are used as-is,
   without prefixing the profile target schema. This gives us clean schema
   names like STAGING/INTERMEDIATE/MARTS/SEEDS instead of MARTS_STAGING etc. #}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
