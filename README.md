# kf-test

Getting git repos working

```
EC2_IP=1.2.3.4

SSH_KEY_FILE=jm-utility
SSH_KEY_DIR=$SECRETS/utility
GITHUB_ORG=lago-morph
REPO=kf-test

ssh-keyscan ${EC2_IP} >> ~/.ssh/known_hosts
ACCESS_KEY=${HOME}/.ssh/my-ubuntu-key.pem
scp -i $ACCESS_KEY ${SSH_KEY_DIR}/${SSH_KEY_FILE} ubuntu@${EC2_IP}:.ssh
scp -i $ACCESS_KEY ${SSH_KEY_DIR}/${SSH_KEY_FILE}.pub ubuntu@${EC2_IP}:.ssh
scp -i $ACCESS_KEY gitconfig ubuntu@${EC2_IP}:.gitconfig

ssh -i $ACCESS_KEY ubuntu@${EC2_IP} "ssh-keyscan github.com >> ~/.ssh/known_hosts"
ssh -i $ACCESS_KEY ubuntu@${EC2_IP} git clone git@github.com:${GITHUB_ORG}/${REPO}

ssh -i $ACCESS_KEY ubuntu@${EC2_IP}
```
