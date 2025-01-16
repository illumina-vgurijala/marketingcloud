- [Salesforce Continous Deployment](#salesforce-continous-deployment)
  * [Description](#description)
  * [Responsibilities](#responsibilities)
  * [Dependencies](#dependencies)
  * [Getting Started](#getting-started)
  * [Commands](#commands)
    + [Regular flow](#regular-flow)
    + [Check Commands](#check-commands)
    + [Branching & Merging](#branching---merging)
    + [Sharing & Updating Projects](#sharing---updating-projects)
  * [Help](#help)
  * [ImportantLinks](#importantlinks)
  * [References](#references)
  * [Weekly Releases](#weekly)

# Salesforce Continous Deployment

This repo contains Salesforce codebase across Sales, Servivce and Marketing workstreams. All salesforce engineers should use this repository for any salesforce related change.

## Description

This document contains basic instructions on setting up source code development environment and how to make code ready for deployments. Document describes the continous deployment process and sets the expectations for all developers involved with Salesforce development.

![image](https://user-images.githubusercontent.com/72516897/220410552-969ee682-8c86-4383-b513-6b0c72ac8af8.png)

## Responsibilities

Sandbox refresh master and cutover master template capture the roles and responsibilities in detail.

| Item  | Role | Description |
| ------| -----| ------------|
| `Data` | `Developer` | It's a developer responsibility to create/modify data (including test data) in all environments. Data updates should be performed through common agreed upon userid.|
|        | `DevOps` | All prod data tasks should be captured in cutover plan. Repetitive data migration tasks should be automated.|
| `Data Backup` | `Developer` |It's a developer responsibility to take data backups before any remediation. Ownbackup tool should be used for data backups before and after data updates. Playbooks should be maintained in Confluence for future references|
|               | `DevOps` | Manage Ownbackup tool, create data and metadata pipeline with salesforce production and sandbox environment. Provide user access and technical help to developers |
| `Metadata`| `Developer` | It's a developer responsibility to checkin bug free code in DEV branch and provide commit ids in <link> |
|           | `DevOps` | Automate release pipeline and manual instructions. Setup release communications and notifications.  |

  
## Dependencies

* IDE preferably Microsoft VS Code with Salesforce DX, salesforce cli and salesforce extensions installed.
* git client or GitHub for Desktop tool.
* Code Scan extension for VS Code.


## Getting Started

(**This is one time step**) Clone the repository from Terminal/Command Prompt: 

    > $ git clone https://github.com/Illumina-SFDC/Salesforce.git 
  
    or 
  
    alternatively download the zipped repository or use GitHub for Desktop to clone the repository in your working folder.
  

## Commands

### Regular flow

| Command | Description |
| ------- | ----------- |
| `git switch -c [branchname]` | Create a branch under the current one|
| `git switch [branchname]` | Switch to branchname |
| `git add [file-name.txt]` | Add a file to the staging area |
| `git add -A or git add .` | Add all new and changed files to the staging area |
| `git commit -m "[commit message]"` | Commit changes |


### Check Commands

| Command | Description |
| ------- | ----------- |
| `git status` | Check status |
| `git log` | Check your git activity log |
| `git log --oneline` | View changes (briefly) |


### Branching - Merging

| Command | Description |
| ------- | ----------- |
| `git branch` | List branches (the asterisk denotes the current branch) |
| `git branch -a` | List all branches (local and remote) |
| `git branch -d [branch name]` | Delete a branch |
| `git merge [branch name]` | Merge a branch into the active branch |
| `git merge [source branch] [target branch]` | Merge a branch into a target branch |
| `git stash` | Stash changes in a dirty working directory |
| `git stash clear` | Remove all stashed entries |

### Sharing - Updating Projects

| Command | Description |
| ------- | ----------- |
| `git push origin [branch name]` | Push a branch to your remote repository |
| `git push -u origin [branch name]` | Push changes to remote repository (and remember the branch) |
| `git push` | Push changes to remote repository (remembered branch) |
| `git pull` | Update local repository to the newest commit |
| `git pull origin [branch name]` | Pull changes from remote repository |


## Help
  
Reach out to vgurijala@illumina.com, asachan@illumina.com, rhota@illumina.com or hsrinivasulu@illumina.com

Any advise for common problems or issues.
```
WIP - Will be added as an when issues are encountered. This will be continous learning section
```

## ImportantLinks

- [Sandbox refresh plan](https://illumina.quip.com/KDtsAoZOMmAI/Sandbox-Refresh-Plan-Master#temp:C:IaTd0f0b93b495946879bf920f8e)
- [Sandbox master refresh template](https://illumina.quip.com/bwncALGN2dqM/Sandbox-Refresh-Steps-Master-Template#PKPACA73uQi)
- [Cutover master template](https://illumina.quip.com/bzVfAXajYFba/Quarterly-PROD-CutoverMaster-Template#temp:C:DaT921a8d08ab1a4f16ad131324d)
- [Playbooks](https://confluence.illumina.com/display/SfdcSales/Playbooks)
- [Main Site](https://confluence.illumina.com/pages/viewpage.action?pageId=740835745)
- [Platform Monitoring Site](https://confluence.illumina.com/display/SfdcSales/Operations+Management+Process)
- [Release Calendar](https://confluence.illumina.com/display/SfdcSales/GIS+Release+Management)


## References  

- [Git cheat sheet](https://training.github.com/downloads/github-git-cheat-sheet/)
- [Git complete documentation](https://git-scm.com/docs)
- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

## Weekly Releases

![image](https://user-images.githubusercontent.com/72516897/233111823-e3fadac2-4196-491b-a97c-0ab9efe8fbf0.png)

