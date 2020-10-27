#! /bin/bash

### example
# sh wrapper.sh --repo make-novice --create
# sh wrapper.sh --repo make-novice --import
# sh wrapper.sh --repo make-novice --account GitHubUser --import
# sh wrapper.sh --repo r-novice-gapminder --account swcarpentry-ja --import --webpages

# create (implemented):      subroutine to create new PO files from an English lesson not currently being translated
# import (testing):          subroutine to pull a lesson being translated from remote to make changes locally
# webpages (testing): subroutine to render webpages from current PO files and export Japanese lessons to remote repos
# update (to-do later):      subroutine to pull updates from remote English lesson and merge based on archived ancestor (only new sections need to be translated)


pc_user=`whoami`
echo $pc_user account for pc `hostname`
git_user=`git config user.name`
remote_user=$git_user
git_email=`git config user.email`                                                            
remote_account=$git_user
echo $git_user \<${git_email}\> account detected for git
next=false
create=false
import=false
render=false
for op in "$@"; do
    if $next; then
        next=false;
        continue;
    fi
    case "$op" in
        -u|--user)
        shift
            if [[ $1 != "" ]]; then
                # pass different git user name to local account
                git_user="${1/%\//}"
                # keep username case-sensitive
                # git_user=`echo "$git_user" | tr '[:upper:]' '[:lower:]'`
                next=true
                shift
            else
                git_user=`git config user.name`
                next=true
            fi
            ;;
        -c|--create)
        shift
            create=true
            next=true
            ;;
        -i|--import)
        shift
            import=true       
            next=true
            ;;
        -a|--account)
        shift
            if [[ $1 != "" ]]; then
                remote_user="${1/%\//}"       
                next=true
            else
                echo "specify remote account for: $git_user"
                remote_user=$git_user
                next=true
            fi
         shift
            ;;
        -r|--repo)
        shift
            if [[ $1 != "" ]]; then
                repo="${1/%\//}"
                next=true
            else
                all_repo=true
                next=true
            fi
        shift
            ;;
       -w|--webpages)
        shift
            render=true
            next=true
            ;;
        -u|--update)
        shift
            update=true
            next=true
            ;;
        -*)
            echo "Error: Invalid option: $op"
            exit 1
            ;;
    esac
done

if [[ $import == true ]]; then
    if [[ $create == true ]]; then
        echo "Warning: it is not recommended to --create and --import at the same time" 
    fi
    create=$create
fi

if [[ $import == true ]] || [[ $create == true ]]; then
    if [[ -z $repo ]]; then
        echo all available repos to import: $all_repos
    else
        echo repo to create or import: $repo
    fi
fi


echo create ${repo} : $create
echo import ${repo} : $import
echo render webpages : $render

#check if remote i18n repo exists
root_dir=`git ls-remote https://github.com/${remote_user}/i18n.git | grep "ja$" | wc -l`
echo i18n repo: $root_dir
if [ $root_dir -eq 1 ]; then
    echo "remote found:  https://github.com/${remote_user}/i18n.git"
elif [ $root_dir -eq 0 ]; then
    echo remote not found for user repo:  https://github.com/${remote_user}/i18n.git \n please create a fork
    exit 1
else
    echo ambiguous repo:
    git ls-remote https://github.com/${remote_user}/i18n.git
    exit 1
fi

#check if remote repo exists
root_dir=`git ls-remote https://github.com/${remote_user}/${repo}.git | grep "gh-pages$" | wc -l`
echo $repo repo: $root_dir
if [ $root_dir -eq 1 ]; then
    echo "remote found:  https://github.com/${remote_user}/${repo}.git"
elif [ $root_dir -eq 0 ]; then
    echo remote not found for user repo:  https://github.com/${remote_user}/${repo}.git \n please create a fork
    exit 1
else
    echo ambiguous repo:
    git ls-remote https://github.com/${remote_user}/${repo}.git
    exit 1
fi


if [[ $create == true ]]; then
    echo "runnning"
    if [[ -d i18n ]]; then
        cd i18n
    fi
    #check if current working directory is i18n
    wd="${PWD##*/}"
    echo $wd

    if [[ $wd != "i18n" ]]; then  
    echo "create i18n directory"
    git clone https://github.com/${git_user}/i18n.git
    cd i18n
    fi
    git pull origin ja

    #checkout Japanese branch
    git checkout ja
    if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
        then
        git remote remove remote-repo
    fi
    git remote add remote-repo git@github.com:${git_user}/i18n.git
    git pull remote-repo ja
   
    #import submodules
    git submodule init
    git submodule add git@github.com:${git_user}/${repo}
 
    echo "update local submodules"
    git submodule update -f --recursive $repo

    #remove _locale directory (only translate English lessons)
    for dir in `git submodule |  grep "^+"  | cut -d" " -f2`
        do
        if [ -d $dir ]
            then
            cd $dir
            if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
                then
                git remote remove remote-repo
            fi
            #reset all repos to remote
            url=https://github.com/${git_user}/${dir}.git
            git remote add remote-repo $url
             if [[ `git branch -v | grep "master" | wc -l` -ge 1 ]]
                then
                git pull master -f
            fi
            git remote add remote-repo $url                                          
            if [[ `git branch -v | grep "gh-pages" | wc -l` -ge 1 ]]
                then
                git branch -D gh-pages
            fi
            git checkout -b gh-pages  `git rev-list HEAD | tail -n 1`
            git pull remote-repo gh-pages -f
            git add -u
            git commit -m "reset branch"
            git checkout HEAD
            rm -rf _locale
            cd ..
        fi
    done


    if [[ ! -z $repo ]]; then
        if [[ -d $repo ]]; then
            echo submodule $repo found
        else
            git submodule add https://github.com/swcarpentry/${repo}.git
        fi
    fi
    if [[ -z $repo ]];then
        echo "warning $repo not found, specify --repo <lesson name> --create"
        exit 1
    fi

    echo "run import on po4gitbook"
    po4gitbook/import.sh > /dev/null 2>&1
    echo "upated PO files exported"
    if [[ -f po/${repo}.ja.po ]]; then
        echo "Warning: file po/${repo}.ja.po already exists: check for conflicts and import"
        exit 1
    else
        echo "creating PO file for $repo"
        cp po/${repo}.pot po/${repo}.ja.po 
        git add  po/${repo}.ja.po
        #archive PO file from English lessons for merging updates
        if [[ -f po/.ancestors/.${repo}.jp.po.ancestor ]]; then
            echo "Warning file po/${repo}.ja.po already archived in po/.ancestors"
       else
            echo "archiving PO file for $repo"
            mkdir -p po/.ancestors
            cp po/${repo}.pot po/.ancestors/.${repo}.ja.po.ancestor
            git add po/.ancestors/.${repo}.ja.po.ancestor
       fi

        #fill in missing information for Japanese
        year=`date +%Y`
        sed -i '1s/# SOME DESCRIPTIVE TITLE./# Japanese translation of the Software Carpentry ${repo} Lesson/g' po/${repo}.ja.po
        sed -i "2s/# Copyright \(C\) YEAR THE PACKAGE\'S COPYRIGHT HOLDER/# Copyright \(C\) ${year} Software Carpentry Foundation; Japanese Translation Team/g" po/${repo}.ja.po
        sed -i '3s/# This file is distributed under the same license as the PACKAGE package./# This file is distributed under the same license as the git4pobook package./g'  po/${repo}.ja.po
        sed -i '4s/# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR./# ${git_user} <${git_email}>, ${year}./g' po/${repo}.ja.po
        sed -i '12s/"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"/"Last-Translator: ${git_user} <${git_email}>\n"/g'  po/${repo}.ja.po
        sed -i '13s/Language-Team: LANGUAGE <LL@li.org>\n/Language-Team: Japanese <tomkellygenetics@gmail.com>\n/g'  po/${repo}.ja.po
        sed -i '14 i "Language: ja\n"' po/${repo}.ja.po
        #remove Japanese from LINGUAS if already exists
        sed -i '1s/ ja//g' po/LINGUAS
        #add Japanese to LINGUAS
        sed -i '1s/$/ ja/g' po/LINGUAS 
    fi   
    git add  po/${repo}.ja.po
    echo "removing extraneous PO files"
    rm po/*.pot
    echo "run compile on po4gitbook to create new lessson"
    po4gitbook/compile.sh  > /dev/null 2>&1
    echo lesson $repo created in _locale/ja/$repo

    #restore _locale directory (only translate English lessons)
    for dir in `git submodule |  grep "^+"  | cut -d" " -f2`
        do
        if [ -d $dir ]
            then
            cd $dir
            git reset --hard
            cd ..
        fi
    done

fi

if [[ $import == true ]]; then
    echo "runnning"
    if [[ -d i18n ]]; then
        cd i18n
    fi
    #check if current working directory is i18n
    wd="${PWD##*/}"
    echo $wd

    if [[ $wd != "i18n" ]]; then  
    echo "create i18n directory"
    git clone https://github.com/${git_user}/i18n.git
    cd i18n
    fi

    #checkout Japanese branch
    git checkout ja
    if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
        then
        git remote remove remote-repo
    fi
    git remote add remote-repo git@github.com:${git_user}/i18n.git
    git pull remote-repo ja
   
    #import submodules
    git submodule init
    git submodule foreach 'git pull remote-repo'       
    git submodule add git@github.com:${git_user}/${repo}
 
    echo "update local submodules"
    git submodule update -f --recursive

    #remove _locale directory (only translate English lessons)
    for dir in `git submodule |  grep "^+"  | cut -d" " -f2`
        do
        if [ -d $dir ]
            then
            cd $dir
            if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
                then
                git remote remove remote-repo
            fi
            #reset all repos to remote
            url=https://github.com/${git_user}/${dir}.git
            git remote add remote-repo $url                                          
             if [[ `git branch -v | grep "master" | wc -l` -ge 1 ]]
                then
                git pull master -f      
            fi
            git remote add remote-repo $url
            if [[ `git branch -v | grep "gh-pages" | wc -l` -ge 1 ]]
                then
                git branch -D gh-pages
            fi
            git checkout -b gh-pages  `git rev-list HEAD | tail -n 1`
            git pull remote-repo gh-pages -f
            git add -u
            git commit -m "reset branch"
            git checkout HEAD
            rm -rf _locale
            cd ..
        fi
    done


    if [[ ! -z $repo ]]; then
        if [[ -d $repo ]]; then
            echo "lesson repo found: ${repo} found"
        else
            echo "lesson repo ${repo} not found, run:\n sh wrapper.sh --repo ${repo} --create"
        fi
    fi
    if [[ -z $repo ]];then
        echo "warning $repo not found, specify --repo <lesson name> --import"
        exit 1
    fi

    if [[ -f po/${repo}.ja.po ]]; then
        echo "Warning: file po/${repo}.ja.po exists: please edit file and submit pull request"
        exit 0
    else
        echo "Warning: file po/${repo}.ja.po not found, run:\n sh wrapper.sh --repo ${repo} --create"
        exit 1
    fi   
fi

if [[ $render == true ]]; then
    echo "runnning"
    if [[ -d i18n ]]; then
        cd i18n
    fi
    #check if current working directory is i18n
    wd="${PWD##*/}"
    echo $wd

    if [[ $wd != "i18n" ]]; then
    echo "create i18n directory"
    git clone https://github.com/${git_user}/i18n.git
    cd i18n
    fi

    #checkout Japanese branch
    git checkout ja
    if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
        then
        git remote remove remote-repo
    fi
    git remote add remote-repo git@github.com:${git_user}/i18n.git
    git pull remote-repo ja

    #import submodules
    git submodule init
    git submodule add git@github.com:${git_user}/${repo}

    echo "import local submodules"
    git submodule update -f --recursive

    if [[ ! -z $repo ]]; then
        if [[ -d $repo ]]; then
            echo "lesson repo found: ${repo} found"
        else
            echo "lesson repo ${repo} not found, run:\n sh wrapper.sh --repo ${repo} --create"
        fi
    fi
    if [[ -z $repo ]];then
        echo "warning $repo not found, specify --repo <lesson name> --import"
        exit 1
    fi

    if [[ -f po/${repo}.ja.po ]]; then
        echo "File po/${repo}.ja.po exists: exporting translated lesson"
    else
        echo "Warning: file po/${repo}.ja.po not found, run:\n sh wrapper.sh --repo ${repo} --create"
        exit 1
    fi   

    #correct dates in headers
    year=`date +%Y`
    past_year=$(( $year-1 ))
    #replace past year with current year
    sed -i "2s/$past_year/$year/g" po/*.po
    # append current year if different to previous year
    sed -i "4s/, ${past_year}\./, ${past_year}, ${year}./g" po/*po

    #create all Japanese lessons
    echo "run compile on po4gitbook"
    po4gitbook/compile.sh > /dev/null 2>&1

    #commit updates to source PO files
    git pull remote-repo ja
    git add -u po/*ja.po
    git commit -m "update PO files"
    git push remote-repo ja

    echo "translated lessons from  po/${repo}.ja.po  exported to _locale/ja/$repo"

    #check if remote translated lesson exists 
    lesson_dir=`git ls-remote https://github.com/${remote_user}/${repo}-ja.git | grep "master" | wc -l`
    echo ${repo}-ja repo: $lesson_dir
    if [ $lesson_dir -eq 1 ]; then
        echo "remote found:  https://github.com/${remote_user}/${repo}-ja.git"
    elif [ $root_dir -eq 0 ]; then
        echo remote not found for user repo:  https://github.com/${remote_user}/${repo}-ja.git please create a new empty repo
        exit 1
    else
        echo ambiguous repo:
        git ls-remote https://github.com/${remote_user}/${repo}-ja.git
        exit 1
    fi
   
    #create as submodule
    #git submodule add https://github.com/${remote_user}/${repo}-ja.git _locale/ja/$repo
    ##git submodule absorbgitdirs <path>

    #create external ja repo
    mkdir -p ../${repo}-ja

    #add update lessons to remote
    cd ../${repo}-ja
    git init
    if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
        then
        git remote remove remote-repo
    fi
    remotes=`git remote | grep "remote-repo" | wc -l`
    if [[ remotes -le 0 ]]; then
        git remote add remote-repo https://github.com/$remote_user/$repo-ja.git 
    fi
    git pull remote-repo master

    #move files to external repo
    rsync -r ../i18n/locale/ja/${repo}/*md ../i18n/locale/ja/${repo}/*/*md .

    # remove files provided by template
    rm -rf bin/boilerplate
    rm -rf _layouts _includes _episodes_rmd assets bin code 

    git add *
    git commit -m "update lesson files"
    git push remote-repo master
    echo "lesson $repo-ja pushed to ${remote_user}/$repo-ja"

    #update original lesson to import translated content
    cd ../i18n # or English lesson
    # restore to version from remote
    git submodule update -f --recursive
    # import changes from org repo
    git submodule foreach 'case $name in po4gitbook) ;; *) git checkout gh-pages; git pull -f remote-repo gh-pages ;; esac'

    #restore _locale lessons (only English lessons translated)
    for dir in `git submodule |  grep "^+"  | cut -d" " -f2`
      do
      if [ -d $dir ] 
        then
        cd $dir
        git checkout gh-pages
        if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
            then
            git remote remove remote-repo
        fi
        remotes=`git remote | grep "remote-repo" | wc -l`
        if [[ remotes -le 0 ]]; then
           git remote add remote-repo https://github.com/$remote_user/${dir}.git
        fi
        git pull remote-repo gh-pages
        cd ..
      fi
    done  

    #create external repo
    mkdir -p ../${repo}

    #add update lessons to remote
    cd ../${repo}
    git init
    if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
        then
        git remote remove remote-repo
    fi
    remotes=`git remote | grep "remote-repo" | wc -l`
    if [[ remotes -le 0 ]]; then
        git remote add remote-repo https://github.com/$remote_user/${repo}.git
    fi
    if [[ `git branch -v | grep "gh-pages" | wc -l` -ge 1 ]]; then
        git checkout -b gh-pages
    fi
    git checkout gh-pages
    git pull remote-repo gh-pages
    git submodule update -f --recursive 

    #add changes
    git add -u

    #create lesson in _locale if not existing or update
    if [ -d ./_locale/ja ]
        then
        cd _locale/ja
        git init
        git checkout master
        git add -u
        git commit -m "update Japanese lessons"
        remotes=`git remote | grep "origin" | wc -l`
        if [[ remotes -le 0 ]]; then
            git remote add origin https://github.com/$remote_user/${repo}-ja.git
        fi
        git pull origin master
        pwd
        cd ../..
    else
        mkdir -p _locale
        url="https://github.com/${remote_user}/${repo}-ja.git"
        git submodule add $url ./_locale/ja
    fi

    cd _locale/ja
    if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
        then
        git remote remove remote-repo
    fi
    remotes=`git remote | grep "remote-repo" | wc -l`
    if [[ remotes -le 0 ]]; then
        git remote add remote-repo https://github.com/${remote_user}/$repo-ja.git
    fi
    git checkout master
    git pull remote-repo master
    cd ../..
 
    #push updated _locale lessons to English lesson
    git checkout gh-pages
    git pull remote-repo gh-pages
    git add -u
    git commit -m "update Japanese lessons"
    if [ `git remote -v | grep "remote-repo" | wc -l` -ge 1 ]
        then
        git remote remove remote-repo
    fi
    remotes=`git remote | grep "remote-repo" | wc -l`
    if [[ remotes -le 0 ]]; then
        git remote add remote-repo https://github.com/${remote_user}/$repo.git
    fi

    git push remote-repo gh-pages
    echo "lesson $repo pushed to ${remote_user}/$repo with locale $repo-ja"

    cd ../i18n
git submodule update -f --recursive  
fi

echo "run complete!"
