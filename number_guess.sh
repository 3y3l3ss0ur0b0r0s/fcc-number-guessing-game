#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=users -t --no-align -c"

MAIN () { 
  # get username
  echo "Enter your username:"
  read INPUT

  # check length of INPUT: https://www.geeksforgeeks.org/how-to-find-length-of-string-in-bash-script/#
  LENGTH=${#INPUT}

  if [[ $LENGTH -lt 23 && $LENGTH -gt -1 ]]
    then
      # set default values for GAMES_PLAYED and BEST_GAME
      GAMES_PLAYED=0
      BEST_GAME=0

      # query the database for the username
      USERNAME=$($PSQL "SELECT username FROM users WHERE username = '$INPUT'")
      if [[ "$USERNAME" = "$INPUT" ]]
        then
          # if the username exists already, welcome the user back and sum up their info
          GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username = '$USERNAME'")
          BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME'")
          echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
        else
          # if the username doesn't exist yet, welcome them and add them to the database
          USERNAME=$INPUT
          echo "Welcome, $USERNAME! It looks like this is your first time here."
          INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username,games_played,best_game) VALUES('$USERNAME',0,0)")
        fi

        # after usernames are taken care of, play the game
        # generate random number
        RANDOM_NUMBER=$((RANDOM % 1000 + 1))
        #echo "$RANDOM_NUMBER - $USERNAME - $GAMES_PLAYED - $BEST_GAME"
        PLAY_GAME $RANDOM_NUMBER 1 $USERNAME $GAMES_PLAYED $BEST_GAME
    else
      echo "Username is not 1 to 22 characters long."
    fi
}

PLAY_GAME() {
  NUMBER=$1
  GUESSES=$2
  USER=$3
  GAMES=$4
  BEST=$5

  # if this is the first guess, then act like it
  if [[ $2 -eq 1 ]]
    then 
        echo "Guess the secret number between 1 and 1000:"
  fi

  read GUESS

  # check whether guess is an integer
  if [[ $GUESS =~ ^[1-9][0-9]*$ ]]
    then
      if [[ $GUESS -gt $NUMBER ]]
        then
          echo "It's lower than that, guess again:"
          GUESSES=$((GUESSES+1))
          PLAY_GAME $NUMBER $GUESSES $USER $GAMES $BEST

        elif [[ $GUESS -lt $NUMBER ]]
          then
            echo "It's higher than that, guess again:"
            GUESSES=$((GUESSES+1))
            PLAY_GAME $NUMBER $GUESSES $USER $GAMES $BEST
        else
          GUESSES=$((GUESSES+1))
          echo "You guessed it in $GUESSES tries. The secret number was $NUMBER. Nice job!"

          # update user data

          # number of games played:
          GAMES=$((GAMES+1))
          UPDATE_GAMES_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES WHERE username='$USER'")

          # best game:
          if [[ $GUESSES -lt $BEST ]] || [[ $BEST -eq 0 ]]
            then
              UPDATE_BEST_RESULT=$($PSQL "UPDATE users SET best_game=$GUESSES WHERE username='$USER'")
            fi
        fi
    else
      # if the guess isn't an integer, prompt for another guess but don't increment
      echo "That is not an integer, guess again:"
      PLAY_GAME $NUMBER $GUESSES $USER $GAMES $BEST
    fi
}

MAIN
