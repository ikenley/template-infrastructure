--
-- configure postgresql db for knowledge base vector store
-- https://docs.aws.amazon.com/amazonrds/latest/aurorauserguide/aurorapostgresql.vectordb.html
--

create extension if not exists vector;
select extversion from pg_extension where extname='vector';

-- YOU MUST CHANGE THE PASSWORD VALUE
create role bedrock_user with password 'password' login;

--
-- create schema and grant permissions
--
create schema if not exists bedrock_integration;

create role bedrock_integration_reader;
create role bedrock_integration_writer;

grant bedrock_integration_reader to bedrock_integration_writer;

grant usage on schema bedrock_integration to bedrock_integration_reader;

alter default privileges in schema bedrock_integration grant select on tables to bedrock_integration_reader;
alter default privileges grant usage, select on sequences to bedrock_integration_reader;

alter default privileges in schema bedrock_integration grant insert, update, delete on tables to bedrock_integration_writer;


-- grant permissions to bedrock_user
grant bedrock_integration_writer to bedrock_user;
grant all on schema bedrock_integration to bedrock_user;


-- create tables
create table bedrock_integration.bedrock_kb (id uuid primary key, embedding vector(1024), chunks text, metadata json);
create index on bedrock_integration.bedrock_kb using hnsw (embedding vector_cosine_ops);
create index on bedrock_integration.bedrock_kb using hnsw (embedding vector_cosine_ops) with (ef_construction=256);