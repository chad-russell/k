-- SQL script to create the linkwarden database and user
-- Run this against your postgres-cluster before deploying Linkwarden
-- Create the linkwarden user
CREATE USER linkwarden WITH ENCRYPTED PASSWORD '4tCrH2Wb4nUy27';
-- Create the linkwarden database
CREATE DATABASE linkwarden OWNER linkwarden;
-- Grant necessary privileges
GRANT ALL PRIVILEGES ON DATABASE linkwarden TO linkwarden;
-- Connect to the linkwarden database and grant schema privileges
\ c linkwarden;
GRANT ALL ON SCHEMA public TO linkwarden;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO linkwarden;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO linkwarden;
-- Ensure the user can create tables and other objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO linkwarden;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO linkwarden;