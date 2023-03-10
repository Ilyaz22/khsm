# (c) goodprogrammer.ru

# Стандартный rspec-овский помощник для rails-проекта
require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

# Тестовый сценарий для модели Игры
#
# В идеале — все методы должны быть покрыты тестами, в этом классе содержится
# ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    create(:game_with_questions, user: user)
  end

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      }.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
        )
      )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    # Правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # Текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # Перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # Ранее текущий вопрос стал предыдущим
      expect(game_w_questions.current_game_question).not_to eq(q)

      # Игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! finishes the game' do
      # берем игру и отвечаем на текущий вопрос
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      # взяли деньги
      game_w_questions.take_money!

      prize = game_w_questions.prize
      expect(prize).to be > 0

      # проверяем что закончилась игра и пришли деньги игроку
      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end
  end

  context '.status' do
    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  describe '#current_game_question' do
    it 'returns current_game_question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[0])
    end
  end

  describe '#previous_level' do
    it 'returns previous_level' do
      expect(game_w_questions.previous_level).to eq(-1)
    end
  end

  # describe '#answer_current_question!' do

  #   it 'test correct answer' do
  #     expect(game_w_questions.answer_current_question!('d')).to eq(true)
  #     expect(game_w_questions.status).to eq(:in_progress)
  #   end

  #   it 'test incorrect answer' do
  #     expect(game_w_questions.answer_current_question!('c')).to eq(false)
  #     expect(game_w_questions.status).to eq(:fail)
  #   end

  #   context 'test last answer' do 
  #     let!(:level_max) { Question::QUESTION_LEVELS.max }

  #     it 'correct answer' do
  #       game_w_questions.current_level = level_max
  #       expect(game_w_questions.answer_current_question!('d')).to eq(true)
  #       expect(game_w_questions.current_level).to eq(level_max + 1)
  #       expect(game_w_questions.status).to eq(:won)
  #     end

  #     it 'incorrect answer' do
  #       game_w_questions.current_level = level_max
  #       expect(game_w_questions.answer_current_question!('a')).to eq(false)
  #       expect(game_w_questions.status).to eq(:fail)
  #     end
  #   end

  #   it 'test answer time is over' do
  #     game_w_questions.created_at = 1.hour.ago
  #     expect(game_w_questions.answer_current_question!('d')).to eq(false)
  #     expect(game_w_questions.status).to eq(:timeout)
  #   end
  # end

  describe '#answer_current_question!' do
    before { game_w_questions.answer_current_question!(answer_key) }
    let!(:answer_key) { game_w_questions.current_game_question.correct_answer_key }

    context 'when answer is correct' do
      let!(:level) { game_w_questions.current_level }

      it 'return current level' do
        expect(game_w_questions.current_level).to eq(1)
      end

      it 'not finished' do
        expect(game_w_questions.finished?).to eq(false)
      end

      it 'return status - in_progress' do
        expect(game_w_questions.status).to eq(:in_progress)
      end
    end

    context 'and question is last' do
      before do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max
        game_w_questions.answer_current_question!(answer_key)
      end
      
      it 'finished' do
        expect(game_w_questions.finished?).to eq(true)
      end

      it 'return status - won' do
        expect(game_w_questions.status).to eq(:won)
      end
    end

    context 'when answer incorrect' do
      let!(:answer_key) { game_w_questions.answer_current_question!('a') }

      it 'finished' do
        expect(game_w_questions.finished?).to eq(true)
      end

      it 'return status - fail' do
        expect(game_w_questions.status).to eq(:fail)
      end
    end

    context 'when answer time is over' do
      before do
        game_w_questions.created_at = 1.hour.ago
        game_w_questions.answer_current_question!(answer_key)
      end

      it 'finished' do
        expect(game_w_questions.finished?).to eq(true)
      end

      it 'return status - timeout' do
        expect(game_w_questions.status).to eq(:timeout)
      end
    end
  end
end
