# Spotify Data Analytics

This project runs multiple queries on a cleaned dataset containing Spotify data metrics 

## Features
- Imports data from CSV file into PostgreSQL database
- Platform comparison per track (Spotify vs YouTube) with deltas/ratios
- Platform comparison per track (Spotify vs YouTube) with deltas/ratios
- Global vs within-artist ranks

## Files
- `cleaned_dataset.csv`: Dataset containing song, artist, and platform analytics
- `export_to_table.py`: Python script to extract data from .csv and upload into PostgreSQL databsae
- `SpotifyQueries.sql`: SQL file creating table within database and performing multiple queries on data
