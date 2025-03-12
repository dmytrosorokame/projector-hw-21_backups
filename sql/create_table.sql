CREATE TABLE if not exists books (
  id SERIAL PRIMARY KEY,
  category_id int not null,
  title VARCHAR(50) NOT NULL
);