#!/bin/bash

# HEADER

# @Author Angelos-Giannis
# @Version v0.0.1

#
#+ Usage and details of this script :
#+ ==================================
#+ Execution
#+ -----------
#+ $(basename $0) [-f] [-u]
#+ 
#+ Description
#+ -----------
#+ The purpose of this script is to automatically create a builder of a given
#+                   class/object under the respective builder path.
#+ Options
#+ -----------
#+   Helping
#+     -h  : Displays the usage of the script (this description).
#+     -s  : How to setup in Php Storm.
#+   Mandatory
#+     -b  : Directory where the builder should live.
#+     -f  : Filename of the class upon which we need the builder to be created.
#+     -r  : Root path of the project (will be used to properly create the builder class).
#+   Optional
#+     -a  : Define whether you need a buildFromArrayFunction to be created or not (default = false).
#+     -c  : Constructor extra definition.
#+     -d  : Dependecies for the builder class.
#+     -n  : Namespace of the builder class.
#+     -p  : Private variables that will be used in the builder.
#+
#

#
#- Steps to set up on Php Storm for this script
#- ============================================
#-   1. Open PhpStorm -> Preferences
#-   2. Search for "External Tools"
#-   3. Click on add "+"
#-   4. In the prompt that opens :
#-       4.1 Give a name you want
#-       4.2 Add it to a group of your preference
#-       4.3 Set : 
#-           Program   : <your dir>/createBuilderForClass.sh
#-           Arguments : 
#-               * In case you want a buildFromArrayFunction to be created use this :
#-                   -f $FilePath$ -r $ContentRoot$ -b "<path to store builder>" -n "<builder namespace>" -a
#-               * In case you don't want the buildFromArrayFunction function to be included use this :
#-                   -f $FilePath$ -r $ContentRoot$ -b "<path to store builder>" -n "<builder namespace>"
#-       4.4 Click "OK" to close the prompt
#-   5. Click "Apply"
#-   6. Click "OK" to close the Preferences
#-   7. On right click on a desired file, on the bottom of the options that show up, you will find your group
#-   8. Simply click on the name of you have given in step 4.1
#-   9. Voila!! Your builder has just been created!!!!
#-
#

# END_OF_HEADER

SCRIPT_HEADSIZE=$(head -200 ${0} |grep -n "^# END_OF_HEADER" | cut -f1 -d:)
SCRIPT_NAME="$(basename ${0})"

#
# __createBuilder performs the required steps to create the builder.
#
function __createBuilder() {
    filename=$1
    root_path=$2
    builder_directory=$3
    create_build_from_array_function=$4
    builder_namespace=$5
    builder_dependencies=$6
    private_constructor_variables=$7
    builder_constructor=$8

    # Retrieve the namespace for the class.
    namespace=$(__getNamespaceOfClass $filename)

    # Retrieve the class to prepare the builder.
    class_name=$(__getClassName $filename)

    # Retrieve the name of the variable name of the object to build.
    global_var_name=$(__snakeCase $class_name)

    # Retrieve the builder class name.
    builder_class_name=$(__getBuilderClassName $filename)

    # Create the builder file.
    builder_file=$(__createBuilderClass $root_path $builder_directory $builder_class_name)

    # Open the builder class with the constructor and build functions and write them to the builder class file.
    __builderClassOpen "${namespace}" "${class_name}" "${builder_class_name}" "${global_var_name}" "${builder_namespace}" "${builder_dependencies}" "${private_constructor_variables}" "${builder_constructor}" > $builder_file

    # Public variables of the base class.
    public_vars=($(__getPublicVariablesOfClass $filename))

    # If need to create a buildFromArray function, here it is generated and writter to the builder file.
    [[ $create_build_from_array_function == true ]] && __createBuildFromArrayFunction $global_var_name ${public_vars[@]} >> $builder_file

    # Create the with<Something> functions of the builder class and write them to the builder class file.
    for public_var in "${public_vars[@]}"
    do
        data_type=$(__getDataTypeOfField $filename $public_var)

        camel_case=$(__camelCase $public_var)

        with_func=$(__getWithValueFunction $builder_class_name $public_var $global_var_name $camel_case $data_type)
        echo "$with_func" >> $builder_file
    done

    # Close the builder class with the create<Class> function and write it to the builder class file.
    __builderClassClose $class_name >> $builder_file
}

#
# __builderClassOpen prepares the opening of the builder class.
#
function __builderClassOpen() {
    class_path=$1
    class_name=$2
    builder_class_name=$3
    instance_variable_name=$4
    builder_namespace=$5
    builder_dependencies=$6
    private_constructor_variables=$7
    builder_constructor=$8

    #
    # Check if all the provided arguments have value and if not add the respective todos.
    #
    [[ $builder_namespace == "" ]] && builder_namespace="/** @todo define namespace */"
    [[ $builder_dependencies == "" ]] && builder_dependencies="/** @todo Define dependencies for the builder (e.g. DI). */"
    [[ $private_constructor_variables == "" ]] && private_constructor_variables="/** @todo Define any required private variables for the builder. */"
    [[ $builder_constructor == "" ]] && builder_constructor="/** @todo Define any required steps for constructor. */"
    
    echo -e "<?php

declare(strict_types = 1);

namespace ${builder_namespace};

${builder_dependencies}
use ${class_path}\\${class_name};

class ${builder_class_name}
{
    ${private_constructor_variables}

    /** @var ${class_name} \$${instance_variable_name} */
    private \$${instance_variable_name};

    public function __construct()
    {
        ${builder_constructor}

        \$this->$4 = new ${class_name}();
    }
    
    /**
     * Creates the ${class_name} in the database and returns it.
     *
     * @return ${class_name}
     */
    public function build() : ${class_name}
    {
        \$this->create${class_name}();

        return \$this->${instance_variable_name};
    }"
}

#
# __builderClassClose closes the builder class.
#
function __builderClassClose() {
    class_name=$1

    echo -e "
    /**
     * Stores the ${class_name} in the database.
     *
     * @return void
     */
    public function create$1() : void
    {
        /**
         * @todo Implement the object persistence function.
         */
    }
}"
}

#
# __snakeCase convert a camel case string to snake case.
#
function __snakeCase() {
    echo $1 | sed -e 's/\([A-Z]\)/\_\1/g' -e 's/\_//' | tr '[:upper:]' '[:lower:]'
}

#
# __camelCase convert a snake case string to camel case.
#
function __camelCase() {
    echo $1 | perl -pe 's/(^|_)./uc($&)/ge;s/_//g'
}

#
# __getDataTypeOfField retrieve the type for each field in class.
#
function __getDataTypeOfField() {
    filename=$1
    public_var=$2

    data_type=$(grep -B 1 -w $public_var $filename | grep "@var" | awk -F'@var' '{print $NF}' | awk -F' ' '{print $1}')

    single_data_type=$(echo ${data_type} | sed 's/null//g' | sed 's/\|//g')

    [[ $data_type == *"null"* ]] && echo "?${single_data_type}" || echo $single_data_type
}

#
# __createBuildFromArrayFunction prepares the buildFromArray function for the builder.
#
function __createBuildFromArrayFunction() {
    builder_class_variable=$1
    public_variables=("${@:2}")

    example_array="["
    build_sequence="(new self())"

    iterator=0
    for pb_var in "${public_variables[@]}"
    do
        example_array="${example_array}\"${pb_var}\", "

        camel_case=$(__camelCase $pb_var)

        build_sequence="${build_sequence}
                ->with${camel_case}(\$dt[${iterator}])"
        iterator=`expr $iterator + 1`
    done

    example_array="${example_array}]"
    example_array=$(echo $example_array | sed 's/, ]$/]/g')

    echo -e "
    /**
     * Builds a batch of offline reasons based on a provided array of the form :
     * [
     *     ${example_array},
     *     ${example_array},
     * ]
     * 
     * @param array \$details
     *
     * @return array
     */
    public function buildFromArray(array \$details) : array
    {
        \$${builder_class_variable}_array = [];

        foreach (\$details as \$dt) {
            \$${builder_class_variable}_array[] = ${build_sequence}
                ->build();
        }

        return \$${builder_class_variable}_array;
    }"
}

#
# __getWithValueFunction prepares the withSomething function in the builder.
#
function __getWithValueFunction() {
    builder_class_name=$1
    initial_class_element=$2
    instance_variable_name=$3
    camel_case_class_element=$4
    data_type=$5
    param_data_type=$5
    fix_data_type_todo=""

    if [[ $data_type == "" ]]; then
        data_type="string"
        param_data_type="string"
        fix_data_type_todo=" @todo Fix the datatype (if needed)."
    else
        if [[ $data_type == *"?"* ]]; then
            param_data_type=$(echo $data_type | sed 's/?//g')
            param_data_type="${param_data_type}|null"
        fi
    fi

    echo -e "
    /**
     * Set the value for ${initial_class_element}.
     *
     * @param ${param_data_type} \$${initial_class_element}
     *
     * @return ${builder_class_name}
     */
    public function with${camel_case_class_element}(${data_type} \$${initial_class_element}) : ${builder_class_name}
    {
        \$this->${instance_variable_name}->${initial_class_element} = \$${initial_class_element};

        return \$this;
    }"
}

#
# __getNamespaceOfClass retrieves the namespace in which the class belongs to.
#
function __getNamespaceOfClass() {
    echo $(grep "namespace " $1 | awk -F' ' '{print $2}' | sed 's/;//g')
}

#
# __getClassName retrieves the class name of the object.
#
function __getClassName() {
    echo $(grep "class " $1 | awk -F' ' '{print $2}')
}

#
# __getBuilderClassName retrieves the class bane that the builder will have.
#
function __getBuilderClassName() {
    echo $(grep "class " $1 | awk -F' ' '{print $2"Builder"}')
}

#
# __getPublicVariablesOfClass retrieves the public variables of a class.
#
function __getPublicVariablesOfClass() {
    echo $(grep "public " $1 | awk -F' ' '{print $2}' | sed s/';'//g | sed s/'\$'//g)
}

#
# __createBuilderClass is responsible to create the required builder file.
#
function __createBuilderClass() {
    root_dir=$1
    builder_dir=$2
    builder_class_name=$3

    builder_file="${root_dir}/${builder_dir}/${builder_class_name}.php"
    touch $builder_file
    echo $builder_file
}

#
# __getUsage returns the usage of this script.
#
function __getUsage() {
    head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#+" $0 | sed 's/^#+//g' | sed "s/\$(basename \$0)/${SCRIPT_NAME}/g"
}

#
# __getPhpStormSetup returns the setup required for php storm.
#
function __getPhpStormSetup() {
    head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#-" $0 | sed 's/^#-//g'
}

#
# createBuilderForObjectClass is the "main" function the performs the required checks
# and executes the required steps.
#
function createBuilderForObjectClass() {
    OPTION=$1

    create_build_from_array_function=false
    filename=""
    root_path=""
    builder_directory=""
    builder_namespace=""
    builder_dependencies=""
    private_constructor_variables=""
    builder_constructor=""

    while getopts ab:c:d:f:hn:p:r:s OPTION; do
        case "$OPTION" in
            a)
                create_build_from_array_function=true
                ;;
            b)
                builder_directory="${OPTARG}"
                ;;
            c)
                builder_constructor="${OPTARG}"
                ;;
            d)
                builder_dependencies="${OPTARG}"
                ;;
            f)
                filename="${OPTARG}"
                ;;
            n)
                builder_namespace="${OPTARG}"
                ;;
            p)
                private_constructor_variables="${OPTARG}"
                ;;
            r)
                root_path="${OPTARG}"
                ;;
            h)
                __getUsage >&2
                return
                ;;
            s)
                __getPhpStormSetup >&2
                return
                ;;
            ?)
                __getUsage >&2
                return
                ;;
            *)
                echo "Invalid arguments provided!!" >&2
                __getUsage >&2
                return
                ;;
        esac
    done

    if [[ $filename == "" || $root_path == "" || $builder_directory == "" ]]; then
        __getUsage >&2
        exit 1
    fi

    __createBuilder "${filename}" "${root_path}" "${builder_directory}" "${create_build_from_array_function}" "${builder_namespace}" "${builder_dependencies}" "${private_constructor_variables}" "${builder_constructor}"

    exit 0
}

#
# Run the main function to execute the whole process of creating a builder class.
#
createBuilderForObjectClass "$@"
