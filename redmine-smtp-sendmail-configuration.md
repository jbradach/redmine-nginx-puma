# Redmine SMTP and Sendmail Configuration

> Now that you have Redmine up and running, let's configure it to send and receive emails. For this tutorial you'll either need a locally installed Sendmail server or credentials for an SMTP server. If you don't have either of these, you can create a Gmail account for your Redmine installation and use the SMTP service that comes with it.

## Configuration File

Copy the template configuration file and take a look at the examples provided.

```shell
cp redmine/config/configuration.yml.example redmine/config/configuration.yml
nano redmine/config/configuration.yml
```

This is where you tell Redmine how it should be sending mail. You can customize the settings for each environment individually, or you can just set default mail settings used for all environments. I'm configuring the default settings.

If you scroll past the examples in the comments, you'll come to an uncommented default configuration using SMTP. You can either modify this for your situation, or you can comment out the lines if you want to create your own from scratch.

```yaml
# default configuration options for all environments
default:
  # Outgoing emails configuration (see examples above)
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      address: "smtp.example.net"
      port: 25
      domain: "example.net"
      authentication: :login
      user_name: "redmine@example.net"
      password: "redmine"
```

### SMTP No Authorization

Since there's no authorization required for this SMTP server, the authentication, user_name, and password fields are not needed. Here I just commented the lines out, but they could also have been deleted from the file just the same.

```yaml
default:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      address: "smtp.example.net"
      port: 25
      domain: "<YOURDOMAIN>"
      #authentication: :login
      #user_name: "redmine@example.net"
      #password: "redmine"
```

### SMTP with Login Authentication

```yaml
production:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      address: "smtp.example.net"
      port: 25
      authentication: :login
      domain: "<YOURDOMAIN>"
      user_name: "<YOURUSERNAME>"
      password: "<YOURPASSWORD>"
```

### SMTP with Plain Authentication

```yaml
production:
 email_delivery:
   delivery_method: :smtp
   smtp_settings:
     address: "smtp.example.net"
     port: 25
     authentication: :plain
     domain: "<YOURDOMAIN>"
     user_name: "<YOURUSERNAME>"
     password: "<YOURPASSWORD>"
```

### SMTP Gmail with TLS

To send using Gmail's SMTP servers, the port should be set to either 465 or 587 (rather than 25) and a line should be added to enable TLS/SSL.

```yaml
default:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      enable_starttls_auto: true
      address: "smtp.gmail.com"
      port: '465'
      domain: "smtp.gmail.com"
      authentication: :plain
      user_name: "<YOURUSERNAME>@gmail.com"
      password: "<YOURPASSWORD>"
```

### SMTP Office 365 with TLS

```yaml
production:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      enable_starttls_auto: true
      address: "smtp.office365.com"
      port: "587"
      domain: "<YOURDOMAIN>"
      authentication: :login
      user_name: "<YOUREMAIL>"
      password: "<YOURPASSWORD>"
```

### Sendmail

If you have Sendmail installed on your server, the configuration is just three times.

```yaml
default:
  email_delivery:
    delivery_method: :sendmail
```

## Test Settings

Once you've updated configuration.yml with your mail settings, restart Redmine.

```shell
sudo service redmine restart
```

Confirm that you've updated your account's email address from the admin default at http://<SERVERNAME>/my/account. This address is where notifications will be sent.

Go to the email notification settings under the administration menu. Update the emission email address and hit save. This should be located at http://<SERVERNAME>/settings?tab=notifications.

Once the email address has been updated, you can click the send a test email link at the bottom of the page. If an error message does not appear on the screen rightr away, go to your email to see if the message went through successfully.
