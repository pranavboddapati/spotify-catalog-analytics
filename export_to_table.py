import pandas as pd
from sqlalchemy import create_engine
df = pd.read_csv('/Users/pranav/SpotifySQL/cleaned_dataset.csv')
engine = create_engine('postgresql+psycopg2://postgres:(password)@localhost:5432/spotify')
df.to_sql('spotify', engine, if_exists='replace', index=False)
print("Data imported")
