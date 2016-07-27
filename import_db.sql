DROP TABLE if exists users;
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname CHAR(255) NOT NULL,
  lname CHAR(255) NOT NULL
);
DROP TABLE if exists questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title CHAR(255) NOT NULL,
  body TEXT NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY(user_id) REFERENCES users(id)
);
DROP TABLE if exists question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);
DROP TABLE if exists replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  body TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  replies_id INTEGER,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id),
  FOREIGN KEY(replies_id) REFERENCES replies(id)
);
DROP TABLE if exists question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id),
  FOREIGN KEY(question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Robert', 'Ang'),
  ('Michael', 'Yabut');

INSERT INTO
  questions (title, body, user_id)
VALUES
  ('This is a question?', 'This is the body', (SELECT id FROM users WHERE fname = 'Michael' AND lname = 'Yabut') ),
  ('This is a second question?', 'This is the small body', (SELECT id FROM users WHERE fname = 'Michael' AND lname = 'Yabut') ),
  ('Question Title', 'Question Body', (SELECT id FROM users WHERE fname = 'Robert' AND lname = 'Ang') );

INSERT INTO
  replies (body, user_id, question_id, replies_id)
VALUES
  ('This is the body of reply 1', 2, 1, NULL),
  ('This is the body of another reply 2', 1, 1, 1),
  ('I AM A PARENT REPLY TO QUESTION 2', 1, 2, NULL),
  ('I AM A CHILD OF REPLY 2', 2, 1, 2),
  ('I, TOO, AM A CHILD OF REPLY 2', 2, 1, 2),
  ('I AM A CHILD OF REPLY 2 AS WELL', 1, 1, 2),
  ('BODY QUESTION 2 REPLY 3 IS MY PARENT', 1, 2, 3);

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  (1, 2),
  (2, 1),
  (1, 3),
  (2, 3);

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (2, 2),
  (1, 1),
  (1, 3),
  (2, 1);
