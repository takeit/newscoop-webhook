#!/bin/bash
## Sourcefabric
## Newscoop Packaging Script
## Yorick Terweijden

# Defines the Git URL
URL='https://github.com/'
REPO='sourcefabric/Newscoop.git'
REMOTE_NAME='origin'

# Set some defaults
FORMAT='TAR'
METHOD=''
DEFAULT_COMMIT='master'
COMMIT=''
INCLUDE='NO'
ADD_FETCH='NO'

TARGET_DIR='newscoop_packaging'
PACKAGE_NAME='newscoop-package'
DATE=`date +%Y.%m.%d`
VERSION=$DATE

exit_usage() {
    echo -e "------------------------------------------------------------"
    echo -e "Sourcefabric Newscoop Packaging script"
    echo -e "Usage"
    echo -e "------------------------------------------------------------"
    echo -e "   -h shows this usage"
    echo -e "   -p PACKAGE_NAME"
    echo -e "      The package name"
    echo -e "      Defaults to newscoop-package"
    echo -e "   -v VERSION"
    echo -e "      The package version"
    echo -e "      Defaults to the current date ($DATE)"
    echo -e "   -f FORMAT"
    echo -e "      The output format, can be either ZIP or TAR"
    echo -e "      Defaults to TAR"
    echo -e "   -o PACKAGE_DIR"
    echo -e "      Package dir where the package will be saved"
    echo -e "   -d TARGET_DIR"
    echo -e "      The Git clone TARGET_DIR"
    echo -e "      Defaults to newscoop_packaging"
    echo -e "   -i vendor include"
    echo -e "      includes Composer and the Vendors"
    echo -e "------------------------------------------------------------"
    echo -e "Git checkout method"
    echo -e "Only one of the following can be used."
    echo -e "------------------------------------------------------------"
    echo -e "   -c GIT_COMMIT"
    echo -e "      Defines which GIT COMMIT HASH should be packaged"
    echo -e "      GIT COMMIT HASH needs to be a minimum of 7 characters"
    echo -e "   -b GIT_BRANCH"
    echo -e "      Defines which GIT BRANCH should be packaged"
    echo -e "   -t GIT_TAG"
    echo -e "      Defines which GIT TAG should be packaged"
    echo -e ""
    echo -e "If none is specified it defaults to BRANCH [master]"
    echo -e ""
    echo -e "Advanced settings:"
    echo -e ""
    echo -e "   -r REPO"
    echo -e "      The Repo to pull from"
    echo -e "      Defaults to $REPO"
    echo -e "   -u URL"
    echo -e "      The base URL to pull from"
    echo -e "      Defaults to $URL"
    echo -e "   -n REMOTE_NAME"
    echo -e "      The REMOTE_NAME to pull from"
    echo -e "      Defaults to $REMOTE_NAME"
    echo -e "   -a"
    echo -e "      Tells the script to add a Remote Fork"
    echo -e "      Off by default"
    exit 1
}

# Loop through all the options and set the vars
while getopts ":hc:b:f:t:d::o:p:v:iu:r:n:a" opt; do
    case $opt in
        a)
            ADD_FETCH='YES'
            ;;
        h)
            exit_usage
            ;;
        p)
            PACKAGE_NAME=$OPTARG
            ;;
        v)
            VERSION=$OPTARG
            ;;
        u)
            URL=$OPTARG
            echo "Pulling from URL: $URL"
            echo ""
            ;;
        n)
            REMOTE_NAME=$OPTARG
            echo "Git remote name: $REMOTE_NAME"
            echo ""
            ;;
        r)
            REPO=$OPTARG
            echo "Pulling from Repo: $REPO"
            echo ""
            ;;
        i)
            INCLUDE='YES'
            echo "Including Composer and vendors"
            echo ""
            ;;
        f)
            # Check if FORMAT is either ZIP or TAR
            case ${OPTARG,,} in
                zip)
                    FORMAT='ZIP'
                    ;;
                tar)
                    FORMAT='TAR'
                    ;;
                *)
                    echo "Format $OPTARG unknown" >&2
                    exit_usage
                    ;;
            esac
            echo "Format $FORMAT selected." >&2
            ;;
        c)
            # Check if COMMIT is 7 chars minimum
            if [ -z "$COMMIT" ]; then
                if [ ${#OPTARG} -ge 7 ]; then
                    COMMIT=$OPTARG
                    METHOD='HASH'
                else
                    echo "Error, GIT COMMIT HASH needs to be at least 7 characters: $OPTARG" >&2
                    exit_usage
                fi
            else
                echo -e "Only one method for Git checkout can be specified!"
                echo -e ""
                exit_usage
            fi
            ;;
        b)
            if [ -z "$COMMIT" ]; then
                COMMIT=$OPTARG
                METHOD='BRANCH'
            else
                echo -e "Only one method for Git checkout can be specified!"
                echo -e ""
                exit_usage
            fi
            ;;
        t)
            if [ -z "$COMMIT" ]; then
                COMMIT=$OPTARG
                METHOD='TAG'
            else
                echo -e "Only one method for Git checkout can be specified!"
                echo -e ""
                exit_usage
            fi
            ;;
        d)
            TARGET_DIR=$OPTARG
            ;;
        o)
            PACKAGE_DIR=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit_usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            echo -e ""
            exit_usage
            ;;
    esac
done

if [ $FORMAT = "ZIP" ]; then
    zip --version >> /dev/null
    if [ $? = 127 ]; then
        echo -e "Package ZIP is not installed, install or use TAR"
        echo -e ""
        exit_usage
    fi
fi

if [ -z $COMMIT ]; then
    COMMIT=$DEFAULT_COMMIT
    METHOD="BRANCH"
fi

TARGET_DIR_GIT=$TARGET_DIR
TARGET_DIR_GIT+='/.git'

# Clone the Git repo
if [ ! -d $TARGET_DIR ]; then
    echo "Git $METHOD specified: $COMMIT"
    git clone -o $REMOTE_NAME $URL$REPO $TARGET_DIR
else
    if [ -d $TARGET_DIR_GIT ]; then
        EXISTING_CLONE_URL=`cat $TARGET_DIR_GIT/config |grep -A2 "remote \"$REMOTE_NAME"|grep "$REPO"`
        echo "Git $METHOD specified: $COMMIT"
        echo "Git repo already cloned..."
        if [ -z "EXISTING_CLONE_URL" ]; then
            if [ $ADD_FETCH = "YES" ]; then
                echo "Adding a fork"
                pushd $TARGET_DIR 1> /dev/null
                git remote add $REMOTE_NAME $URL$REPO
                popd 1> /dev/null
            else
                echo "Existing Git repo is not: $REMOTE_NAME $URL$REPO"
                exit;
            fi
        fi
        pushd $TARGET_DIR 1> /dev/null
        git pull $REMOTE_NAME
        popd 1> /dev/null
    else
        echo "Directory $TARGET_DIR exists, please remove or specify a different one with:"
        echo -e "   -d TARGET_DIR"
        echo -e ""
        exit_usage
    fi
fi

# Checkout the Git repo
pushd $TARGET_DIR 1> /dev/null
git clean -xfd
git checkout .
if [ $METHOD == "BRANCH" ]; then
    git checkout $REMOTE_NAME/$COMMIT
else
    git checkout $COMMIT
fi

if [ $? = 0 ]; then
    echo "Git checkout succeeded"
else
    echo "Git checkout failed"
    exit
fi

#cp -R plugins/* newscoop/plugins/

#if [ $? -ne 0 ]; then
#    echo "Copying plugins failed"
#    exit
#fi

#cp -R dependencies/include/* newscoop/include/

#if [ $? -ne 0 ]; then
#    echo "Copying dependencies failed"
#    exit
#fi

find newscoop/ -name .gitignore -exec rm {} \;

if [ $? -ne 0 ]; then
    echo "Removing .gitignore files failed"
    exit
fi

if [ $INCLUDE = "YES" ]; then
    pushd newscoop/ 1> /dev/null
    if [ ! -f composer.phar ]; then
        echo -e "Downloading Composer.phar"
        php -r "eval('?>'.file_get_contents('https://getcomposer.org/installer'));" >> /dev/null
    fi
    echo -e "Installing vendors"
    php composer.phar install --prefer-dist --no-dev
    php composer.phar dumpautoload
    rm -r cache/*
    popd 1> /dev/null
fi

BASENAME=$PACKAGE_NAME-$VERSION

case $FORMAT in
    ZIP)
        zip -9q -r ../../../releases/$PACKAGE_DIR/$BASENAME.zip newscoop/
        if [ $? -ne 0 ]; then
            echo "ZIP failed"
        else
            echo "ZIP successfully created: $BASENAME.zip"
        fi
        exit
        ;;
    TAR)
        tar -czf ../../../releases/$PACKAGE_DIR/$BASENAME.tar.gz newscoop/
        if [ $? -ne 0 ]; then
            echo "TAR failed"
        else
            echo "TAR successfully created: $BASENAME.tar.gz"
        fi
        exit
        ;;
esac
