# twitter-twurl-csv
Using twitters twurl command to get statuses. Then parse the JSON into CSV files for statuses, users and user mentions to loading to RDBMS tables.

## Usage

1. Sign up for a twitter developer account to get auth key/secret 
2. Install ruby `sudo apt-get install ruby`  
3. Install twurl `gem install twurl`  
4. Auth twurl with your key/secret `twurl authorize --consumer-key key --consumer-secret secret`
5. Clone repo `git clone https://github.com/mortie23/twitter-twurl-csv.git`
6. In the cloned directory run `twurl-main.sh` script with arguments as per the header of the file  
