require 'rails_helper'

RSpec.feature 'user views other profile', type: :feature do
  let!(:first_user) { FactoryGirl.create(:user, name: 'Миша') }
  let(:second_user) { FactoryGirl.create(:user) }
  let!(:game) do
    FactoryGirl.create(
    :game,
    user_id: first_user.id,
    is_failed: false,
    current_level: 1,
    prize: 2000,
    created_at: Time.parse('2023.02.26, 19:00'),
    finished_at: Time.parse('2023.02.26, 19:10')
    )
  end

  let!(:another_game) do
    FactoryGirl.create(
    :game,
    user_id: first_user.id,
    is_failed: true,
    current_level: 5,
    prize: 22000,
    created_at: Time.parse('2023.02.26, 23:00'),
    finished_at: Time.parse('2023.02.26, 23:22')
    )
  end

  before { login_as second_user }

  scenario 'success' do
    visit user_path(first_user)

    expect(page).to have_content('Миша')
    expect(page).not_to have_content('Сменить имя и пароль')
    expect(page).to have_content('проигрыш')
    expect(page).to have_content('22 000 ₽')
    expect(page).to have_content('1')
    expect(page).to have_content('деньги')
    expect(page).to have_content('2 000 ₽')
    expect(page).to have_content('5')
    expect(page).to have_content('26 февр., 19:00')
  end
end
