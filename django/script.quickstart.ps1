# follow the steps below to create a new Django project
# https://www.django-rest-framework.org/tutorial/quickstart/

# Create the project directory
mkdir sample-app
cd sample-app

# Create a virtual environment to isolate our package dependencies locally
python -m venv env
# source env/bin/activate  # On Windows use `env\Scripts\activate`
env\Scripts\activate

# Install Django and Django REST framework into the virtual environment
pip install djangorestframework

# Set up a new project with a single application
django-admin startproject tutorialx .  # Note the trailing '.' character
cd tutorialx
django-admin startapp quickstart
cd ..


# sync DB
python manage.py migrate

# create admin user
python manage.py createsuperuser --username admin --email admin@example.com

# run the app
python manage.py runserver

# test the app using Git bash
user='admin'
password='***'
authBas64=$(echo -n $user:$password | base64)
echo $authBas64
curl -u "admin:$password" -H 'Accept: application/json; indent=4' http://127.0.0.1:8000/users/


# build Docker image
$image = 'sample-django-app'
$tag = '0.0.4'
$img = "$($image):$($tag)"
docker build -t $img .

# test Docker image
docker run --name $image -d -p 8000:8000 $img
docker rm $image
docker ps -a
docker logs $image

# obtain image tag from Dockerfile
$c = cat Dockerfile
$line = $c | Select-String -Pattern 'LABEL VERSION='
$line
# $tag = $line | Select-String -Pattern '\d+\.\d+\.\d+' # -AllMatches | ForEach-Object { $_.Matches.Value }
[regex]$regex = '\d+\.\d+\.\d+'
$tag = $regex.Matches($line).Value
$tag

# push to ACR
$image = 'sample-django-app'
# $tag = '0.0.1'
# acr
$registry='acr85618.azurecr.io'
$rns='itp' # namespace

$img="${image}:${tag}"
docker tag ${img} ${registry}/${rns}/${img}
# requires docker login
az acr login --name $registry
docker push ${registry}/${rns}/${img}

# inspect 
docker inspect $img
docker inspect --format='{{.RepoDigests}}' $img
docker images --digests
docker images --no-trunc --quiet $img

# sync to GitHub
git remote add github https://github.com/ivee-tech/demos-calculator-mirror
# Step 1: Create a new orphan branch (replace 'new-history' with your desired branch name)
git checkout --orphan new-history
# Step 2: Add all files to the staging area
git add .
# Step 3: Commit the changes
git commit -m "New history commit - $(Get-Date)"
# Step 4: Force push this new branch to the remote 'main' branch (replace 'origin' with your remote name if different)
git push github new-history:main --force
git checkout main
# git branch -D new-history
