require "selenium-webdriver"

# https://github.com/SeleniumHQ/selenium/wiki/Ruby-Bindings#user-content-internal-timeouts
client = Selenium::WebDriver::Remote::Http::Default.new
client.timeout = 3600 # set the ruby's Net::HTTP lib timeout to 3 min
driver = Selenium::WebDriver.for(:firefox, :http_client => client)

campaign_name = "testcampaign"
domain_name = "http://civicrm.test.com"
drupal_uname = "admin"
drupal_upass = "password"
mysql_table = "civicrm.users"
log_file = "./log"

#http://stackoverflow.com/questions/13677263/check-whether-element-is-present
def is_element_present(d, how, what)
    d.manage.timeouts.implicit_wait = 0
    result = d.find_elements(how, what).size() > 0

    if result
        result = d.find_element(how, what).displayed?
    end

    d.manage.timeouts.implicit_wait = 30
    return result
end

driver.manage.window.maximize
driver.navigate.to domain_name

wait = Selenium::WebDriver::Wait.new(:timeout => 10)
wait.until { is_element_present(driver, :id, "edit-name") }

#auth
uname = driver.find_element(:id, "edit-name")
uname.send_keys drupal_uname

pw = driver.find_element(:id, "edit-pass")
pw.send_keys drupal_upass

submit = driver.find_element(:id, "edit-submit")
submit.click

loop do
i = `tail -n 1 #{log_file}`
i = (i == "") ? 0 : i.to_i

mysql_query = "SELECT * FROM #{mysql_table} LIMIT 1000 OFFSET #{i*1000}"
puts i
sleep 5

wait.until { driver.title.downcase.start_with? "welcome" }
    
driver.navigate.to "#{domain_name}/civicrm/import/contact?reset=1"

wait.until { is_element_present(driver, :id, "dataSource") }

driver.find_element(:id => "dataSource").find_elements(:tag_name => "option").each do |g|
    if g.text == "SQL Query"
        g.click
        break
    end
end

#wait for text box

wait = Selenium::WebDriver::Wait.new(:timeout => 10)
wait.until { is_element_present(driver, :id, "sqlQuery") }

sqlBox = driver.find_element(:id, "sqlQuery")
sqlBox.send_keys mysql_query

# http://stackoverflow.com/questions/11908249/debugging-element-is-not-clickable-at-point-error
wait = Selenium::WebDriver::Wait.new(:timeout => 20)
wait.until { is_element_present(driver, :id, "CIVICRM_QFID_16_8") }
driver.find_element(:id, "CIVICRM_QFID_16_8").click

wait = Selenium::WebDriver::Wait.new(:timeout => 20)
wait.until { is_element_present(driver, :id, "CIVICRM_QFID_4_20") }
driver.find_element(:id => "CIVICRM_QFID_4_20").click

driver.find_element(:id, "savedMapping").find_elements(:tag_name, "option").each do |s|
    if s.text == campaign_name
        s.click
        break
    end 
end

driver.find_element(:id, "_qf_DataSource_upload-bottom").click

wait = Selenium::WebDriver::Wait.new(:timeout => 300)
wait.until { is_element_present(driver, :id, "_qf_MapField_next-bottom") }

driver.find_element(:id, "_qf_MapField_next-bottom").click

wait = Selenium::WebDriver::Wait.new(:timeout => 300)
wait.until { is_element_present(driver, :id, "_qf_Preview_next-bottom") }

driver.find_element(:id, "_qf_Preview_next-bottom").click

#start importing
driver.switch_to.alert.accept

wait = Selenium::WebDriver::Wait.new(:timeout => 1200)
wait.until { is_element_present(driver, :id, "_qf_Summary_next-top") }

driver.find_element(:id, "_qf_Summary_next-top").click

wait = Selenium::WebDriver::Wait.new(:timeout => 10)
wait.until { is_element_present(driver, :id, "_qf_DataSource_upload-top") }

i = i+1
File.open(log_file, 'a') { |file| file.write(i.to_s+"\r\n") }
end
