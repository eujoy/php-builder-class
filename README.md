# Php Builder Class Generator

The purpose of this script/tool is to provide an easy and automated way to create a builder class for a provided class file.

## Usage of the script

```
# Usage and details of this script :
# ==================================
# Execution
# -----------
# createBuilderForClass.sh -f "<class to create a builder for>" -r "<content root>" -b "<path to store builder>"
#
# Description
# -----------
# The purpose of this script is to automatically create a builder of a given
# class/object under the respective builder path.
#
# Options
# -----------
#   Helping
#     -h  : Displays the usage of the script (this description).
#     -s  : How to setup in Php Storm.
#   Mandatory
#     -b  : Directory where the builder should live.
#     -f  : Filename of the class upon which we need the builder to be created.
#     -r  : Root path of the project (will be used to properly create the builder class).
#   Optional
#     -a  : Define whether you need a buildFromArrayFunction to be created or not (default = false).
#     -c  : Constructor extra definition.
#     -d  : Dependecies for the builder class.
#     -n  : Namespace of the builder class.
#     -p  : Private variables that will be used in the builder.
```

## Steps to integrate with Php Storm

```
# Steps to set up on Php Storm for this script
# ============================================
#   1. Open PhpStorm -> Preferences
#   2. Search for "External Tools"
#   3. Click on add "+"
#   4. In the prompt that opens :
#       4.1 Give a name you want
#       4.2 Add it to a group of your preference
#       4.3 Set : 
#           Program   : <your dir>/createBuilderForClass.sh
#           Arguments : 
#               * In case you want a buildFromArrayFunction to be created use this :
#                   -f $FilePath$ -r $ContentRoot$ -b "<path to store builder>" -n "<builder namespace>" -a
#               * In case you don't want the buildFromArrayFunction function to be included use this :
#                   -f $FilePath$ -r $ContentRoot$ -b "<path to store builder>" -n "<builder namespace>"
#       4.4 Click "OK" to close the prompt
#   5. Click "Apply"
#   6. Click "OK" to close the Preferences
#   7. On right click on a desired file, on the bottom of the options that show up, you will find your group
#   8. Simply click on the name of you have given in step 4.1
#   9. Voila!! Your builder has just been created!!!!
```
