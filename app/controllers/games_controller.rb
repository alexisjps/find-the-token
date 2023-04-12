class GamesController < ApplicationController

  def show
    @game = Game.find(params[:id])
    elapsed_time = @game.updated_at - @game.created_at
    @minutes = elapsed_time.to_i / 60
    @seconds = elapsed_time.to_i % 60
  end

  def new
    @game = Game.new
    session[:secret_code] = generate_secret_code if session[:secret_code].nil?
    session[:attempts] = 0 if session[:attempts].nil?
    @attempts = session[:attempts]
  end  

  def create
    @game = Game.new(game_params)
    @game.secret_code = session[:secret_code]
    session[:attempts] = session[:attempts].to_i + 1
    @game.attempts = session[:attempts]
    puts "Secret code: #{session[:secret_code]}"
    
    if session[:start_time].nil?
      session[:start_time] = Time.now.to_i
    end
    
    if @game.save
      result = compare_codes(@game.secret_code, @game.user_guesses)
      flash[:notice] = "Indice: #{result}. Nombre de tentatives: #{@game.attempts}."
      if @game.secret_code == @game.user_guesses
        session[:secret_code] = nil
        session[:attempts] = nil
        elapsed_time = Time.now.to_i - session[:start_time]
        minutes = elapsed_time / 60
        seconds = elapsed_time % 60
        flash[:notice] = "Félicitations, vous avez trouvé le code secret ! Vous avez réussi en #{minutes} minute(s) et #{seconds} seconde(s) et en #{@game.attempts} tentatives."
        session[:start_time] = nil # réinitialiser le temps de départ pour le prochain essai
        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.append(:game_result, partial: "games/result")
          }
          format.html {
            redirect_to new_game_path, notice: flash[:notice]
          }
          format.js {
            flash[:notice] = "#{flash[:notice]}\\nCeci est une alerte de pop-up."
            render :popup
          }
        end
      else
        redirect_to new_game_path
      end
    else
      flash[:alert] = "Erreur lors de la création du jeu. Veuillez réessayer."
      render :new
    end
  end
  

  private

  def game_params
    params.require(:game).permit(:user_guesses, :secret_code, :attempts)
  end

  def generate_secret_code
    secret_code = ""
    4.times { secret_code << rand(1..9).to_s }
    secret_code
  end

  def compare_codes(secret_code, user_guesses)
    result = ""
    user_guesses.chars.each_with_index do |guess, i|
      if guess == secret_code[i]
        result << "+"
      elsif secret_code.include?(guess)
        result << "-"
      end
    end
    result.empty? ? "Aucun chiffre trouvé." : result
  end
end
