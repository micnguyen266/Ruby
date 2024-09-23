### Export data from MySQL to reimport to CiviCRM contacts

1. The goal of this project is to format csv data and import to MySQL. Then run this ruby script in headless mode so that it uses the Selenium webdriver to grab data from the MySQL table and reimport it to CiviCRM contacts. This script helps to avoid to manually enter user data into CiviCRM contacts.
2. Under /root/civicrm have a formatted csv ready. 
3. Save csv file under path/mysql/civicrm<database_civicrm>. This is where we keep the csv files.
4. Command to remove Microsoft character: 
    1. cat contact_data.csv | sed -e 's/[CTRL+V + Ctrl+M]/\n/g' > (redirect output) file2.contact_data.csv
5. To import to the mysql database:
    1. mysql -uroot -p civicrm_table < contact_data.sql
6. Run the Ruby script with forever -c ruby civicrm_import_script.rb