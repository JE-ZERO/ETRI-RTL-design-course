set APP_NAME      $::env(APP_NAME)
set PATH_XSA      $::env(PATH_XSA)
set DIR_WORKSPACE $::env(DIR_WORKSPACE)
#-------------------------------------------------------------------------------
# create app
setws ${DIR_WORKSPACE}

app create -name ${APP_NAME} \
           -hw ${PATH_XSA} \
	   -proc ps7_cortexa9_0 \
	   -os standalone \
	   -lang c\
	   -template {Hello World}

#-------------------------------------------------------------------------------
app config -name ${APP_NAME} \
	   -set compiler-optimization {Optimize (-O1)}
#-------------------------------------------------------------------------------
# compile app
set DIR_SRC       src
#set DIR_SRC ${DIR_WORKSPACE}/${APP_NAME}
importsource -name ${APP_NAME} \
	     -path ${DIR_SRC} \
             -linker-script

app build -name ${APP_NAME}
#-------------------------------------------------------------------------------
