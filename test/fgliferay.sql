drop user if exists liferay;
drop database if exists lportal;
create user "liferay" identified by "liferay";
create database lportal character set UTF8mb4 collate utf8mb4_bin;
grant all privileges on lportal.* TO "liferay"@"localhost" IDENTIFIED BY "liferay";
grant all privileges on lportal.* TO "liferay"@"%" IDENTIFIED BY "liferay";
flush privileges
