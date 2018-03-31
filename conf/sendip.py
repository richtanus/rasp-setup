import subprocess 
import smtplib 
from email.mime.text import MIMEText 
import datetime 
import time 


# Sleep for 1 min otherwise the ip might be not ready
time.sleep(60) 

    

# Change to your own account information 

# Account Information 

to = '[destination]@gmail.com' # Email to send to. 

gmail_user = '[source]@gmail.com' # Email to send from. (MUST BE GMAIL) 

gmail_password = '[source_email_password]' # Gmail password. 

# need to change password above 

      
today = datetime.date.today()  # Get current time/date 

arg='ip route list'  # Linux command to retrieve ip addresses. 

# Runs 'arg' in a 'hidden terminal'. 

p=subprocess.Popen(arg,shell=True,stdout=subprocess.PIPE) 

data = p.communicate()  # Get data from 'p terminal'. 

          

# Set up stmp connection 

smtpserver = smtplib.SMTP('smtp.gmail.com', 587) # Server to use. 

smtpserver.ehlo()  # Says 'hello' to the server 

smtpserver.starttls()  # Start TLS encryption 

smtpserver.ehlo() 

smtpserver.login(gmail_user, gmail_password)  # Log in to server 

            

# Creates the text, subject, 'from', and 'to' of the message. 

msg = MIMEText(data[0]) 

msg['Subject'] = 'IPs For RaspberryPi on %s' % today.strftime('%b %d %Y') 

msg['From'] = gmail_user 

msg['To'] = to 

# Sends the message 

smtpserver.sendmail(gmail_user, [to], msg.as_string()) 

# Closes the smtp server. 

smtpserver.quit() 

             



