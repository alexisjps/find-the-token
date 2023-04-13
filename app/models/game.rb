class Game < ApplicationRecord
    validates :user_guesses, format: { with: /\A\d{4}\z/, message: "doit contenir exactement 4 chiffres" }
end
