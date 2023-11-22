#!/bin/bash

# bash script for tic-tac-toe game

# Features:
#   1. Play with another player on the same PC
#   2. Reset game option (no possibility to save the game)
#   3. Save the game results to file (during exit or when game is finished)
#   4. Load the game from file
#   5. Play with computer

# Initialize the game board
board=(
  [0]='1' [1]='2' [2]='3'
  [3]='4' [4]='5' [5]='6'
  [6]='7' [7]='8' [8]='9'
)

# Other variables
self=$( realpath "$0" )
path=$( dirname "$self" )
player='X'
moves_count=0
save_file=''

reset_game() {
  for i in "${!board[@]}"; do
      board[$i]=$((i + 1))
  done
  moves_count=0
  rm "$save_file"
}

# Create file to save the game
create_save_file () {
  save_file=$( mktemp "$0".XXXXX )
}

# Save game into the file
save_to_file () {
  local file_name=''
  while true
    do
      read -r -p 'Filename: ' file_name
        case $file_name in
          *[![:blank:]]*)
            mv "$save_file" "$path"/"$file_name".txt
            echo "File was saved at $path/$file_name".txt
            break ;;
          *)
        echo "Filename cannot be empty."
      esac
    done
}

save_game() {
  if [ -w "$path" ]
    then
      save_to_file
  else
    echo "Game path has no write permissions. File could not be saved."
    rm "$save_file"
  fi
}

prompt_for_save() {
  PS3='Do you want to save your moves into .txt file? '
  local answer='yes no'

  select ans in $answer
  do
    case $ans in
      yes)
        save_game
        break ;;
      no)
        rm "$save_file"
        break ;;
      *)
      echo 'Please select 1 (yes) or 2 (no).' ;;
    esac
  done
}

display_board() {
  echo " "
  echo "${board[0]} ${board[1]} ${board[2]}"
  echo "${board[3]} ${board[4]} ${board[5]}"
  echo "${board[6]} ${board[7]} ${board[8]}"
  echo " "
}

# Save game into the file
record_moves () {
  # shellcheck disable=SC2129
  echo "-> Move: #$moves_count" >> "$save_file"
  echo " " >> "$save_file"
  display_board >> "$save_file"
  echo " " >> "$save_file"
}

# check current player is winner
check_winner() {
  local symbol="$1"
  if [[ (${board[0]} == "$symbol" && ${board[1]} == "$symbol" && ${board[2]} == "$symbol") ||
    (${board[3]} == "$symbol" && ${board[4]} == "$symbol" && ${board[5]} == "$symbol") ||
    (${board[6]} == "$symbol" && ${board[7]} == "$symbol" && ${board[8]} == "$symbol") ||
    (${board[0]} == "$symbol" && ${board[3]} == "$symbol" && ${board[6]} == "$symbol") ||
    (${board[1]} == "$symbol" && ${board[4]} == "$symbol" && ${board[7]} == "$symbol") ||
    (${board[2]} == "$symbol" && ${board[5]} == "$symbol" && ${board[8]} == "$symbol") ||
    (${board[0]} == "$symbol" && ${board[4]} == "$symbol" && ${board[8]} == "$symbol") ||
    (${board[2]} == "$symbol" && ${board[4]} == "$symbol" && ${board[6]} == "$symbol") ]]; then
    return 0
  else
    return 1
  fi
}

# Check the board is already full
check_full() {
  for cell in "${board[@]}"; do
    if [[ "$cell" != 'X' && "$cell" != 'O' ]]; then
      return 1
    fi
  done
  return 0
}


# Do the move
current_move() {
  local symbol="$1"
  local position
  while true; do
    display_board
    read -r -p "Player $symbol, choose a position (1-9) or another option (e-exit/r-reset): " position
    if [[ $position = 'e' ]]; then
      echo ""
      echo "EXITING THE GAME."
      echo ""
      prompt_for_save
      echo ""
      echo "GOOD BYE."
      exit
    elif [[ $position = 'r' ]]; then
      echo ""
      echo "RESETTING THE GAME. PROGRESS WON'T BE SAVED."
      reset_game
      symbol='X'
    elif [[ ! $position =~ ^[1-9]$ ]]; then
      echo "Invalid input. Choose a position between 1 and 9 OR exit/rest the game (e/r)."
    elif [[ "${board[position - 1]}" == 'X' || "${board[position - 1]}" == 'O' ]]; then
      echo "Position is already taken. Choose another."
    else
      board[position - 1]=$symbol
      break
    fi
  done
}

# Play with another player on the same PC logic
play_with_another_player() {
  local winner=''

  create_save_file

  while true; do
    current_move "$player"
    moves_count=$((moves_count + 1))
    record_moves

    if check_winner "$player"; then
      display_board
      winner="$player"
      break
    elif check_full; then
      display_board
      echo "The board is full! Nobody wins."
      echo "The board is full! Nobody wins." >> "$save_file"
      prompt_for_save
      break
    fi

    # Change player
    if [[ "$player" == 'X' ]]; then
      player='O'
    else
      player='X'
    fi
    done

    if [[ -n "$winner" ]]; then
      echo "Player $winner wins!"
      echo "Player $winner wins!" >> "$save_file"
      prompt_for_save
    fi
}


# Check if there is a record about game is finished in a file
check_game_is_finished() {
  local file_content
  file_content=$(cat "$file_choice")
  if [[ $file_content == *"Player O wins!"* || $file_content == *"Player X wins!"* || $file_content == *"The board is full! Nobody wins."* ]]; then
    echo ""
    echo "The game cannot be continued as it's already finished."
    exit 1
  fi
}

# Update current board while game is loaded from the file
update_board() {
  local temp_board=()
  for ((i = 0; i < ${#last_board}; i++)); do
    temp_board+=("${last_board:i:1}")
  done
  board=("${temp_board[@]}")
}

# Read saved game from file
read_saved_game() {
  local files=()
  local file_choice

  # Load the list of .txt files
  for file in ./*.txt; do
    if [[ -f $file ]]; then
      files+=("$file")
    fi
  done

  # Show the existing files
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "There are no saved game files in the current directory."
    return
  fi

  PS3='Choose the file with the saved game: '
  select file_choice in "${files[@]}" "Cancel"; do
    case $file_choice in
      "Cancel")
        echo "CANCELED."
        return
        ;;
      *)
        echo "Chosen: $file_choice"
        break
        ;;
    esac
  done

  last_board=$(awk '/-> Move: /{board=""; next} {board=board $0 "\n"} END{gsub(/[[:space:]]/, "", board); print board}' "$file_choice")

  check_game_is_finished
  update_board "$last_board"

  moves_count=$(grep -c '^-> Move: ' "$file_choice")

  # Change player if game is loaded
  if (( moves_count != 0 )); then
    if (( moves_count % 2 != 0 )); then
      player='O'
    else
      player='X'
    fi
  fi
}

# Play with computer logic
play_with_computer() {
  local winner=''

  create_save_file

  while true; do
    if [[ $player == 'X' ]]; then
      current_move "$player"
      moves_count=$((moves_count + 1))
      record_moves
    else
      computer_move "$player"
      moves_count=$((moves_count + 1))
      record_moves
    fi

    if check_winner "$player"; then
      display_board
      winner="$player"
      break
    elif check_full; then
      display_board
      echo "The board is full! Nobody wins."
      echo "The board is full! Nobody wins." >> "$save_file"
      prompt_for_save
      break
    fi

    # Change player
    if [[ "$player" == 'X' ]]; then
      player='O'
    else
      player='X'
    fi
  done

  if [[ -n "$winner" ]]; then
    echo "Player $winner wins!"
    echo "Player $winner wins!" >> "$save_file"
    prompt_for_save
  fi
}

# Computer move logic
computer_move() {
  local symbol="$1"
  local position

  while true; do
    position=$(( RANDOM % 9 + 1 ))

    if [[ "${board[position - 1]}" != 'X' && "${board[position - 1]}" != 'O' ]]; then
      board[position - 1]=$symbol
      echo "Computer chose position $position."
      break
    fi
  done
}

# Initiate the game
init_game() {
  echo "Choose an option (1-4): "
  echo "1. Play with another player"
  echo "2. Load saved game (ONLY 'play with another player' mode)"
  echo "3. Play with computer"
  echo "4. Exit"

  read -r choice

  case $choice in
    1)
      play_with_another_player
      ;;
    2)
      read_saved_game
      play_with_another_player
      ;;
    3)
      play_with_computer
      ;;
    4)
      exit
      ;;
    *)
      echo "Invalid choice. Please choose a number between 1 and 4."
      init_game
      ;;
  esac
}

init_game