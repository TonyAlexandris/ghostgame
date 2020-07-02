require "byebug"
require_relative("./player")
class Game
    attr_accessor :dictionary, :players, :fragment, :losses
    def dict
        dic = Hash.new(false)
        File.readlines("dictionary.txt").each do |line|
            dic[line.chomp] = true
        end
        dic
    end

    def initialize(num_players, player_names_array)
        @dictionary = self.dict
        @fragment = ""
        @players = Array.new(num_players) {Player.new}
        @players.each_with_index {|player, i| player.get_name(player_names_array[i])}
        @losses = Hash.new(0)
        @players.each {|player| self.losses[player.name] = 0}
    end

    def current_player
        players[0]
    end

    def previous_player
        players[players.index(self.current_player) - 1]
    end

    def next_player!
        players.rotate!
    end

    def in_dict?(possible)
        dictionary.keys.each do |key|
            next if key.length < possible.length
            comparison = ""
            check = key.split("")
            check[0...possible.length].each {|char| comparison += char}
            return true if comparison == possible
        end
        return false
    end

    def valid_play?(string)
        alph = ("a".."z").to_a
        possible = self.fragment + string
        if alph.include?(string) && in_dict?(possible)
            return true
        else
            return false
        end
    end

    def is_winning_move?(letter)
        leftovers = []
        good_choices = [letter]
        possible = self.fragment + letter
        if dictionary[possible] == true
            return false
        end
        dictionary.keys.each do |key|
            if key.length > possible.length && key.include?(possible)
                leftover = ""
                check = key.split("")
                check.each_with_index {|char, i| leftover += char if i >= possible.length}
                leftovers << leftover
            end
        end
        leftovers.each do |leftover|
            if leftover.length <= players.length
                good_choices << leftover
            end
        end
        if leftovers.all? {|leftover| leftover.length <= players.length}
            return true
        else
            return good_choices
        end
    end


    def take_turn(player, invalid_count = 0)
        puts "Enter a lowercase letter, " + player.name
        if player.name == "ai"
            winning = false
            best_case = false
            losing_moves = []
            alph = ("a".."z").to_a.shuffle
            best_moves = []
            alph.each do |letter|
                if valid_play?(letter)
                    if is_winning_move?(letter) == true
                        self.fragment += letter
                        puts letter
                        puts self.fragment
                        winning = true
                        puts "winning"
                        break
                    elsif is_winning_move?(letter).is_a?(Array)
                        best_moves << is_winning_move?(letter)
                        best_case = true
                    else
                        next
                    end
                end
            end
            if best_case == true && winning == false
                best_move = 0
                best_move_index = 0
                best_moves.each_with_index do |move, i|
                    best_move_index = i if move.length > best_move
                end
                best_letter = best_moves[best_move_index][0]
                self.fragment += best_letter
                puts best_letter
                puts self.fragment
                puts "best case"
            end
            if winning == false && best_case == false
                losing_moves = alph.select {|al| valid_play?(al)}
                losing_move = losing_moves[rand(0...losing_moves.length)]
                self.fragment += losing_move
                puts losing_move
                puts self.fragment
                puts "losing"
            end
            if dictionary[self.fragment] == true
                self.loss(player)
                @fragment = ""
            else
                self.next_player!
            end    
        else

        input = gets.chomp.to_s
        if valid_play?(input)
            self.fragment += input
            puts self.fragment
            if dictionary[self.fragment] == true
                self.loss(player)
                @fragment = ""
            else
                self.next_player!
            end
            invalid_count = 0
        else
            puts "Invalid input"
            invalid_count += 1
            if invalid_count < 3
                take_turn(player, invalid_count)
            else
                self.invalid_loss(player)
                @fragment = ""
                invalid_count = 0
            end
        end
        end
    end

    def record(player)
        ghost = "GHOST"
        message = ""
        ghost[0..(self.losses[player.name] - 1)].each_char.with_index do |char|
            message += char
        end
        message
    end

    def loss(player)
        self.losses[player.name] += 1
        puts "You made the word " + self.fragment
        puts "You lose the round"
        puts "You are a " + self.record(player)
        self.next_player!
        if self.losses[player.name] == 5
            puts "You're out of the game, " + player.name
            players.delete(player)
            self.next_player!
        end
    end

    def invalid_loss(player)
        self.losses[player.name] += 1
        puts "You made 3 invalid guesses"
        puts "You lose the round"
        puts "You are a " + self.record(player)
        self.next_player!
        if self.losses[player.name] == 5
            puts "You're out of the game, " + player.name
            players.delete(player)
            self.next_player!
        end
    end    

    def play_round
        take_turn(self.current_player)
    end

    def run
        while players.length > 1
            self.play_round
        end
        puts "You win, " + players[0].name
    end
end
a = Game.new(2, ["tony", "al"])
#a = Game.new(3, ["tom", "dick", "ai"])
a.run
