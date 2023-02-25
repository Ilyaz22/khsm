require 'rails_helper'

describe 'users/show.html.erb', type: :view do
  before do
    assign(:user, user)
    assign(:games, [FactoryGirl.build(:game)])
    stub_template 'users/_game.html.erb' => 'template'
  end

  let(:user) { FactoryGirl.create(:user, name: 'Миша') }

  context 'when your page' do
    before do 
      sign_in user 
      render
    end

    it 'renders user name' do
      expect(rendered).to match 'Миша'
    end

    it 'renders partial' do
      expect(rendered).to have_content 'template'
    end

    it 'renders link' do
      expect(rendered).to match 'Сменить имя и пароль'
    end
  end

  context "when someone else's page" do
    before { render }

    it 'not render link' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end
