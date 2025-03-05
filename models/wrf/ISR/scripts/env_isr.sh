conda activate gcc_env
export DART_DIR=/shared/DART/DART
export BASE_DIR=/shared/DART/ISR

mkdir -p $BASE_DIR
cd $BASE_DIR
mkdir -p icbc output perts template scripts
cp -R ${DART_DIR}/models/wrf/ISR/scripts/* $BASE_DIR/scripts

cd $BASE_DIR/scripts
sed -i "s|\<EXP_DIR\>|$BASE_DIR|g" param.csh

# Run the setup.csh script to create the proper directory structure and move executables to proper locations.
./setup.csh param.csh
