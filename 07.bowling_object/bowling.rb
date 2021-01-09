#! /usr/bin/env ruby
# frozen_string_literal: true

class Game
  def initialize(shot_text)
    @shot_text = shot_text
  end

  def score
    shots = create_shots(@shot_text)
    frames = create_frames(shots)
    frames.map(&:score).sum
  end

  private

  def create_shots(shot_text)
    shot_text.chars.map { |mark| Shot.new(mark) }
  end

  def create_frames(shots)
    (1..10).map do |n|
      first_shot = shots.shift
      if n == 10
        second_shot = shots.shift
        third_shot = shots.shift
      elsif first_shot.score != 10
        second_shot = shots.shift
      end
      Frame.new(first_shot, second_shot, third_shot, shots)
    end
  end
end

class Frame
  def initialize(first_shot, second_shot, third_shot, shots)
    @first_shot = first_shot
    @second_shot = second_shot
    @third_shot = third_shot
    @bonus_score = calculate_bonus_score(shots)
  end

  def score
    score = 0
    score += @first_shot.score
    score += @second_shot.score if @second_shot
    score += @third_shot.score if @third_shot
    score + @bonus_score
  end

  def strike?
    @first_shot.score == 10
  end

  def spare?
    !strike? && @first_shot.score + @second_shot.score == 10
  end

  private

  def calculate_bonus_score(shots)
    return 0 if shots.empty?

    bonus_score = 0
    if strike?
      bonus_score = shots[0].score + shots[1].score
    elsif spare?
      bonus_score = shots[0].score
    end
    bonus_score
  end
end

class Shot
  def initialize(mark)
    @mark = mark
  end

  def score
    @mark == 'X' ? 10 : @mark.to_i
  end
end

puts Game.new(ARGV[0]).score
