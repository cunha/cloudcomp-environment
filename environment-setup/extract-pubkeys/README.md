# extract-pubkeys

This script processes a zip file exported by Sakai or Moodle to extract usernames and the submitted public keys. We extract NetIDs from the e-mail contained in each student's folder (we ignore whatever they typed in the assignment text box), and check public keys with `ssh-keygen`.  A report is pasted at the end.

The output is a `students.yml` file that is also copied into Ansible's `group_vars` directory for use in the playbooks.
