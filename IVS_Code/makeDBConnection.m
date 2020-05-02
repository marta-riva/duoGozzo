function [conn] = makeDBConnection(databasename_)
% Function to make database connection
% In
%   databasename_ [char]: Database name
% Out
%   conn [char]: Database connection

username = secrets.username;
password = secrets.password;
driver = 'org.postgresql.Driver';
url = ['jdbc:postgresql://localhost:5432/',databasename_];
%
conn = database(databasename_,username,password,driver,url);

end
