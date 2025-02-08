#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.
# Vérifier si le fichier games.csv existe
if [[ ! -f "games.csv" ]]; then
  echo "Error: games.csv file not found."
  exit 1
fi

# Vider les tables avant d'insérer de nouvelles données
echo $($PSQL "TRUNCATE TABLE games, teams;")

# Lire games.csv et insérer les données
tail -n +2 games.csv | while IFS=',' read -r year round winner opponent winner_goals opponent_goals
do
  # Nettoyer les espaces blancs autour des valeurs
  winner=$(echo "$winner" | xargs)
  opponent=$(echo "$opponent" | xargs)

  # Vérifier si l'équipe gagnante existe déjà
  winner_id=$($PSQL "SELECT team_id FROM teams WHERE name='$winner';" | head -n 1 | tr -d '[:space:]')
  if [[ -z $winner_id ]]
  then
    echo "Inserting new team: $winner"
    winner_id=$($PSQL "INSERT INTO teams(name) VALUES('$winner') RETURNING team_id;" | head -n 1 | tr -d '[:space:]')
  fi

  # Vérifier si l'équipe adverse existe déjà
  opponent_id=$($PSQL "SELECT team_id FROM teams WHERE name='$opponent';" | head -n 1 | tr -d '[:space:]')
  if [[ -z $opponent_id ]]
  then
    echo "Inserting new team: $opponent"
    opponent_id=$($PSQL "INSERT INTO teams(name) VALUES('$opponent') RETURNING team_id;" | head -n 1 | tr -d '[:space:]')
  fi

  # Vérifier que les IDs ont bien été récupérés avant d'insérer le match
  if [[ -n $winner_id && -n $opponent_id ]]; then
    insert_query="INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($year, '$round', $winner_id, $opponent_id, $winner_goals, $opponent_goals);"
    echo "Executing query: $insert_query"
    echo $($PSQL "$insert_query")
  else
    echo "Error: Missing team ID, skipping this entry."
  fi

done

# Vérifier le nombre total de lignes insérées dans la table games
games_count=$($PSQL "SELECT COUNT(*) FROM games;" | tr -d '[:space:]')
echo "Total rows in games table: $games_count"

