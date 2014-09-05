# Redmine Forwarding Incoming Email

> By configuring Redmine to receive emails, you'll be able to create issues and comments by email. There are two main methods: forwarding messages from your mail server or fetching them from a your POP3/IMAP.

## Forwarding Messages from Mail Server

In order to forward messages directly to Redmine from your mail server, you'll need to be able to add new email aliases and you'll need enable the API that processes incoming messages.

To enable the API go to the incoming emails settings under the administrative menu. The URL should be http://&lt;YOURSERVER&gt;/settings?tab=mail_handler. On this screen, check **Enable WS for incoming emails**, click **Generate a key**, and then save. You'll need this API key later.

### rdm-mailhandler.rb

Redmine came with a standalone script, **extra/mail_handler/rdm-mailhandler.rb**, that can be used to forward incoming emails via HTTP. A copy of this script should be placed on your mail server and made executable.

Take a loook at rdm-mailhandler's help documentation.

```shell
chmod +x redmine/extra/mail_handler/rdm-mailhandler.rb
./extra/mail_handler/rdm-mailhandler.rb --help
```

It's long, but it's important to see all of the available options. The help output is below as a resource.

```shell
Usage: rdm-mailhandler.rb [options] --url=<Redmine URL> --key=<API key>

Reads an email from standard input and forwards it to a Redmine server through a HTTP request.

Required arguments:
    -u, --url URL               URL of the Redmine server
    -k, --key KEY               Redmine API key

General options:
        --no-permission-check   disable permission checking when receiving
                                the email
        --key-file FILE         full path to a file that contains your Redmine
                                API key (use this option instead of --key if
                                you don't want the key to appear in the command
                                line)
        --no-check-certificate  do not check server certificate
    -h, --help                  show this help
    -v, --verbose               show extra information
    -V, --version               show version information and exit

User creation options:
        --unknown-user ACTION   how to handle emails from an unknown user
                                ACTION can be one of the following values:
                                * ignore: email is ignored (default)
                                * accept: accept as anonymous user
                                * create: create a user account
        --default-group GROUP   add created user to GROUP (none by default)
                                GROUP can be a comma separated list of groups
        --no-account-notice     don't send account information to the newly
                                created user
        --no-notification       disable email notifications for the created
                                user

Issue attributes control options:
    -p, --project PROJECT       identifier of the target project
    -s, --status STATUS         name of the target status
    -t, --tracker TRACKER       name of the target tracker
        --category CATEGORY     name of the target category
        --priority PRIORITY     name of the target priority
    -o, --allow-override ATTRS  allow email content to override attributes
                                specified by previous options
                                ATTRS is a comma separated list of attributes
```

The help also includes a couple examples: 

```shell
No project specified, emails MUST contain the 'Project' keyword:
  rdm-mailhandler.rb --url http://redmine.domain.foo --key secret

Fixed project and default tracker specified, but emails can override
both tracker and priority attributes using keywords:
  rdm-mailhandler.rb --url https://domain.foo/redmine --key secret \
    --project foo \
    --tracker bug \
    --allow-override tracker,priority
```

When submitting emails, users can define various attributes that Redmine will parse and handle appropriately to create their issue or comment.

```shell
Project: Sample
Tracker: Feature
Priority: Low
```

If attributes such as project are missing, Redmine will not know what to do with the message. To avoid this, attributes can be locked in at the time of configuration. If you want to define values for these attributes but still allow user email content to be used when available, --allow-override can be used to identify the attributes that may be overridden.

```shell
rdm-mailhandler.rb --url http://<YOURSERVER> --key <YOURKEY> \
    --project defaultproject --tracker bug --priority normal \
    –-allow-override tracker,priority
```

With this configuration all emails are assigned defaultproject as their project, bug as their tracker, and are given a normal priority. With allow-override here, the user could set their own tracker or priority but they cannot change the project.

To begin using this mail handler, add it as an alias in /etc/aliases. 

```shell
redmine: "|/home/redmine/rdm-mailhandler.rb --url http://<YOURSERVER> --key <YOURKEY> --project defaultproject --tracker bug --priority normal –-allow-override tracker,priority"
```

Rebuild the alias database.

```shell
newaliases
```

Messages to redmine are now creating bug issues for defaultproject.

### sub-mailhandler.py

If you have multiple projects, sub-mailhandler.py can help you avoid the need for constant project overrides in your email. This script scans email headers looking for sub-addresses (redmine+project23@yourdomain.xyz) and when found, passes on the message with the project.

```shell
curl -o /home/redmine/sub-mailhandler.py http://www.redmine.org/attachments/download/6759/sub-mailhandler.py
chmod +x /home/redmine/sub-mailhandler.py
```

```shell
Usage: sub-mailhandler.py -h | -e <email> [ -p <project> ] -- <command-line>

The <command-line> portion is the full rdm-mailhandler.rb command that would
normally be executed as the mail handler. The full path to the executable is
required. This command should not include a project; use the build-in
--project argument instead.

Options:
  -h, --help            show this help message and exit
  -e EMAIL, --email=EMAIL
                        Known email to look for (i.e. redmine recipient)
  -p PROJECT, --project=PROJECT
                        Default project to pass to rdm-mailhandler.rb if there
                        is no subaddress

```

This script goes in front of rdm-mailhander.rb in your alias. You'll have to add the recipient's email and the project argument moves to sub-mailhandler.py.

```shell
redmine: "|/home/redmine/sub-mailhandler.py --email redmine@<YOURSERVER> --project defaultproject -- /home/redmine/rdm-mailhandler.rb --url http://<YOURSERVER> --tracker bug --allow-override tracker,priority --key <YOURKEY>"
```
With this configuration, any email sent to redmine@<YOURSERVER> will use defaultproject. If you wish to send to a particular project, you can still do so by emailing redmine+projectname@<YOURSERVER>.
