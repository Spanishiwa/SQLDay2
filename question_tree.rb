require 'sqlite3'
require 'singleton'

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname, :id

  def initialize(options)
    @fname = options['fname']
    @lname = options['lname']
    @id = options['id']
  end

  def self.all
    data = QuestionsDBConnection.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id(id)
    user_data = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      users.id = ?
    SQL
    user_data.map{ |datum| User.new(datum) }
  end

  def liked_questions
    QuestionLikes.liked_questions_for_user_id(@id)
  end

  def self.find_by_name(fname, lname)
    name_data = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
  SQL
    name_data.map {|datum| User.new(datum) }
  end


  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end

  def avg_karma

    # qs = self.authored_questions.length
    # acc = 0
    # self.authored_questions.each do |question|
    #   acc += question.likers.length
    # end
    # acc.fdiv(qs)

    karmas = QuestionsDBConnection.instance.execute(<<-SQL, @id)
      SELECT
        COUNT(question_likes.id)/CAST(COUNT(DISTINCT(questions.id)) AS FLOAT)
      FROM
        questions
        JOIN
          users ON users.id = questions.user_id
        LEFT OUTER JOIN
          question_likes ON question_likes.question_id = questions.id
      WHERE
        users.id = ?
    SQL
    karmas

  end

  def save
    if @id
      update
    else
      QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
      SQL
      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end

  def update
    QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end
end

class Question
  attr_accessor :body, :title, :id, :user_id
  def initialize(options)
    @body = options['body']
    @title = options['title']
    @id = options['id']
    @user_id = options['user_id']
  end

  def self.find_by_id(id)
    question_data = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.id = ?
    SQL
    question_data.map{ |datum| Question.new(datum) }
  end

  def self.find_by_author_id(author_id)
    question_data = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.user_id = ?
    SQL
    return question_data.map{ |datum| Question.new(datum) }
  end

  def likers
    QuestionLikes.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLikes.num_likes_for_question_id(@id)
  end

  def author
    User.find_by_id(@user_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollows.followers_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollows.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLikes.most_liked_questions(n)
  end

  def save
    if @id
      QuestionsDBConnection.instance.execute(<<-SQL, @body, @title, @user_id, @id)
      UPDATE
        questions
      SET
        body = ?, title = ?, user_id = ?
      WHERE
        id = ?
      SQL
    else
      QuestionsDBConnection.instance.execute(<<-SQL, @body, @title, @user_id)
      INSERT INTO
        questions(body, title, user_id)
      VALUES
        (?, ?, ?)
      SQL
      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end
end

class Reply
  attr_accessor :body, :user_id, :question_id, :id, :replies_id

  def initialize(options)
    @body = options['body']
    @user_id = options['user_id']
    @question_id = options['question_id']
    @replies_id = options['replies_id']
    @id = options['id']
  end

  def self.find_by_id(id)
  reply_data = QuestionsDBConnection.instance.execute(<<-SQL, id)
  SELECT
    *
  FROM
    replies
  WHERE
    replies.id = ?
  SQL
  reply_data.map{ |datum| Reply.new(datum) }
  end

  def self.find_by_user_id(user_id)
    find_data = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      user_id = ?
  SQL
    find_data.map{ |datum| Reply.new(datum)}
  end

  def self.find_by_question_id(question_id)
    find_data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      question_id = ?
    SQL
    find_data.map {|datum| Reply.new(datum)}

  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    Reply.find_by_id(@replies_id)
  end

  def child_replies
    child_data = QuestionsDBConnection.instance.execute(<<-SQL, @id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies_id = ?
    SQL
    child_data.map {|datum| Reply.new(datum)}

  end

  def save
    if @id
      QuestionsDBConnection.instance.execute(<<-SQL, @body, @user_id, @question_id, @replies_id, @id)
        UPDATE
          replies
        SET
          body = ?, user_id = ?, question_id = ?, replies_id = ?
        WHERE
          id = ?
      SQL
    else
      QuestionsDBConnection.instance.execute(<<-SQL, @body, @user_id, @question_id, @replies_id)
        INSERT INTO
          replies (body, user_id, question_id, replies_id)
        VALUES
          (?, ?, ?, ?)
      SQL
      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end
end

class QuestionFollows
  attr_accessor :user_id, :question_id, :id

  def initialize(options)
    @user_id = options['user_id']
    @question_id = options['question_id']
    @id = options['id']
  end

  def self.find_by_id(id)
  question_follows_data = QuestionsDBConnection.instance.execute(<<-SQL, id)
  SELECT
    *
  FROM
    question_follows
  WHERE
    question_follows.id = ?
  SQL
  question_follows_data.map{ |datum| QuestionFollows.new(datum) }
  end

  def self.followers_for_question_id(question_id)
    user_data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      users
      JOIN
        question_follows ON users.id = question_follows.user_id
    WHERE
      question_id = ?
    SQL
    user_data.map{ |datum| User.new(datum) }
  end

  def self.followed_questions_for_user_id(user_id)
    question_data = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
        JOIN
          question_follows ON questions.id = question_follows.question_id
      WHERE
        question_follows.user_id = ?
    SQL
    question_data.map {|datum| Question.new(datum)}
  end

  def self.most_followed_questions(n)
    question_data = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        questions
        JOIN
          question_follows ON questions.id = question_follows.question_id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(*) DESC
        LIMIT ?
    SQL
    question_data.map {|datum| Question.new(datum)}
  end

end

class QuestionLikes
  attr_accessor :user_id, :question_id, :id

  def initialize(options)
    @user_id = options['user_id']
    @question_id = options['question_id']
    @id = options['id']
  end

  def self.find_by_id(id)
  question_likes_data = QuestionsDBConnection.instance.execute(<<-SQL, id)
  SELECT
    *
  FROM
    question_likes
  WHERE
    question_likes.id = ?
  SQL
  question_likes_data.map{ |datum| QuestionLikes.new(datum) }
  end

  def self.likers_for_question_id(question_id)
    user_data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
        JOIN
          question_likes ON question_likes.user_id = users.id
      WHERE
        question_id = ?
    SQL
    user_data.map {|datum| User.new(datum)}
  end

  def self.num_likes_for_question_id(question_id)
    var = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(*)
      FROM
        questions
        JOIN
          question_likes ON question_likes.question_id = questions.id
      WHERE
        question_id = ?

    SQL
    var.first.values.first

  end

  def self.liked_questions_for_user_id(user_id)
    question_data = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
    SELECT
      questions.*
    FROM
      questions
      JOIN
        question_likes ON questions.id = question_likes.question_id
    WHERE
      question_likes.user_id = ?
    SQL

    question_data.map{ |datum| Question.new(datum) }
  end

  def self.most_liked_questions(n)
    question_data = QuestionsDBConnection.instance.execute(<<-SQL, n)
    SELECT
      questions.*
    FROM
      questions
      JOIN
        question_likes ON questions.id = question_likes.question_id
    GROUP BY
      questions.id
    ORDER BY
      COUNT(*) DESC
    LIMIT ?
    SQL
    question_data.map {|datum| Question.new(datum)}
  end




end
