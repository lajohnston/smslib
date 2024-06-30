project_dir="$(cd "$(dirname "$0")" && pwd -P)"
build_dir=$project_dir/dist

mkdir -p $build_dir

# Assemble ROM
assemble() {
    name=$1
    entry_dir=$project_dir/$(dirname "$2")
    entry_file=$(basename "$2")

    # Create simple link_file
    link_file="${build_dir}/${name}_link_file"
    echo [objects] > $link_file
    echo $name.o >> $link_file

    # Assemble object files
    cd $entry_dir
    wla-z80 -o $build_dir/$name.o $entry_file

    # Create ROM from object files
    cd $build_dir
    wlalink -d -S -A $link_file $name.sms

    # Delete temp files
    rm -f $build_dir/$name.o $link_file
}

# Assemble ROMs
assemble smslib-tests suite.asm