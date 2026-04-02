for dir in kitty i3 nvim; do
    path="$HOME/.config/$dir"
    if mkdir -p "$path"; then
        echo "OK: $path"
    else
        echo "FAIL: $path"
    fi
done

echo "Creating symlinks..."
ln -sf $(pwd)/kitty.conf $HOME/.config/kitty/kitty.conf
ln -sf $(pwd)/i3_config $HOME/.config/i3/config
ln -sf $(pwd)/init.lua $HOME/.config/nvim/init.lua



echo "All done!"
