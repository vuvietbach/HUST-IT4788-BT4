# Project description
These are backend and frontend code for a sign-in application.The backend is written with python language, while the frontend is flutter.

# Step to run application
## Prerequisites
- A running mondodb instance at localhost:27017. To learn how to setup mongodb, visit https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-os-x/#std-label-install-mdb-community-macos
- Conda installed
- Flutter installed
## Getting Started
- First create conda environment by excuting this command in bash shell: conda env create -f environment.yml
- Second, run backend code. uvicorn main:app --reload       
- Third run front end code by initating emulator device(note: only accept emulator) then run flutter run  
