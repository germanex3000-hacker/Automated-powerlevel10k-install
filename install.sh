# Powerlevel10k installation script for automated installation
# By: Germanex3000

#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current platform detection
PLATFORM="unknown"
case "$(uname -s)" in
    Linux*)     PLATFORM="Linux";;
    Darwin*)    PLATFORM="macOS";;
    CYGWIN*)    PLATFORM="Cygwin";;
    MINGW*)     PLATFORM="MinGW";;
    *)          PLATFORM="Other"
esac

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages based on platform
install_package() {
    local package=$1
    print_status "Installing $package..."
    
    case $PLATFORM in
        "Linux")
            if command_exists apt; then
                sudo apt update && sudo apt install -y "$package"
            elif command_exists dnf; then
                sudo dnf install -y "$package"
            elif command_exists yum; then
                sudo yum install -y "$package"
            elif command_exists pacman; then
                sudo pacman -S --noconfirm "$package"
            elif command_exists zypper; then
                sudo zypper install -y "$package"
            else
                print_error "Package manager not found for Linux"
                return 1
            fi
            ;;
        "macOS")
            if command_exists brew; then
                brew install "$package"
            else
                print_error "Homebrew not found. Please install Homebrew first."
                return 1
            fi
            ;;
        *)
            print_error "Unsupported platform for automatic package installation: $PLATFORM"
            return 1
            ;;
    esac
}

# Function to install Zsh
install_zsh() {
    if command_exists zsh; then
        print_success "Zsh is already installed: $(zsh --version)"
        return 0
    fi
    
    print_status "Zsh not found. Installing Zsh..."
    install_package zsh
    
    if command_exists zsh; then
        print_success "Zsh installed successfully: $(zsh --version)"
        return 0
    else
        print_error "Failed to install Zsh"
        return 1
    fi
}

# Function to set Zsh as default shell
set_zsh_default() {
    if [ "$SHELL" = "$(which zsh)" ]; then
        print_success "Zsh is already the default shell"
        return 0
    fi
    
    print_status "Setting Zsh as default shell..."
    chsh -s "$(which zsh)"
    
    if [ $? -eq 0 ]; then
        print_success "Zsh set as default shell. Please log out and back in for changes to take effect."
    else
        print_warning "Could not set Zsh as default shell. You may need to run: chsh -s \$(which zsh)"
    fi
}

# Function to install Nerd Fonts
install_nerd_font() {
    local font_dir="${HOME}/.local/share/fonts"
    local font_name="MesloLGS NF"
    
    case $PLATFORM in
        "Linux"|"macOS")
            mkdir -p "$font_dir"
            
            # Download MesloLGS NF font
            print_status "Downloading Nerd Font..."
            curl -L -o "${font_dir}/MesloLGS NF Regular.ttf" \
                "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
            curl -L -o "${font_dir}/MesloLGS NF Bold.ttf" \
                "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
            curl -L -o "${font_dir}/MesloLGS NF Italic.ttf" \
                "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
            curl -L -o "${font_dir}/MesloLGS NF Bold Italic.ttf" \
                "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
            
            # Update font cache (Linux)
            if command_exists fc-cache; then
                fc-cache -f -v
            fi
            
            print_success "Nerd Font installed to ${font_dir}"
            print_warning "Please manually set your terminal font to 'MesloLGS NF'"
            ;;
        *)
            print_warning "Please manually install a Nerd Font from: https://www.nerdfonts.com/"
            ;;
    esac
}

# Function to install via Oh My Zsh
install_omz() {
    if [ -d "${HOME}/.oh-my-zsh" ]; then
        print_success "Oh My Zsh is already installed"
        return 0
    fi
    
    print_status "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    if [ -d "${HOME}/.oh-my-zsh" ]; then
        print_success "Oh My Zsh installed successfully"
        return 0
    else
        print_error "Failed to install Oh My Zsh"
        return 1
    fi
}

# Function to install via Antigen
install_antigen() {
    local antigen_path="${HOME}/antigen.zsh"
    
    if [ -f "$antigen_path" ]; then
        print_success "Antigen is already installed"
        return 0
    fi
    
    print_status "Installing Antigen..."
    curl -L git.io/antigen > "$antigen_path"
    
    if [ -f "$antigen_path" ]; then
        print_success "Antigen installed successfully"
        return 0
    else
        print_error "Failed to install Antigen"
        return 1
    fi
}

# Function to install Powerlevel10k
install_powerlevel10k() {
    local method=$1
    
    case $method in
        "oh-my-zsh")
            print_status "Installing Powerlevel10k via Oh My Zsh..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
                "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k"
            
            # Add to .zshrc
            if [ -f "${HOME}/.zshrc" ]; then
                sed -i.bak 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "${HOME}/.zshrc"
            fi
            ;;
        "antigen")
            print_status "Installing Powerlevel10k via Antigen..."
            if [ -f "${HOME}/.zshrc" ]; then
                # Backup .zshrc
                cp "${HOME}/.zshrc" "${HOME}/.zshrc.bak"
                
                # Add antigen configuration
                cat << 'EOF' >> "${HOME}/.zshrc"

# Antigen configuration
source ~/antigen.zsh
antigen theme romkatv/powerlevel10k
antigen apply
EOF
            fi
            ;;
        "manual")
            print_status "Installing Powerlevel10k manually..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
                "${HOME}/powerlevel10k"
            
            # Add to .zshrc
            if [ -f "${HOME}/.zshrc" ]; then
                echo "source ~/powerlevel10k/powerlevel10k.zsh-theme" >> "${HOME}/.zshrc"
            fi
            ;;
    esac
    
    print_success "Powerlevel10k installed via $method method"
}

# Main installation function
main_installation() {
    local install_method=$1
    local install_font=$2
    
    print_status "Starting Powerlevel10k installation on $PLATFORM..."
    
    # Install Zsh
    if ! install_zsh; then
        print_error "Zsh installation failed. Aborting."
        exit 1
    fi
    
    # Install font if requested
    if [ "$install_font" = "yes" ]; then
        install_nerd_font
    fi
    
    # Install chosen method
    case $install_method in
        "oh-my-zsh")
            if install_omz; then
                install_powerlevel10k "oh-my-zsh"
            fi
            ;;
        "antigen")
            if install_antigen; then
                install_powerlevel10k "antigen"
            fi
            ;;
        "manual")
            install_powerlevel10k "manual"
            ;;
    esac
    
    # Set Zsh as default
    set_zsh_default
    
    print_success "Installation completed successfully!"
    print_warning "Please:"
    print_warning "1. Log out and back in to use Zsh"
    print_warning "2. Configure your terminal to use a Nerd Font"
    print_warning "3. Run 'p10k configure' to customize Powerlevel10k"
}

# Interactive menu
show_menu() {
    echo -e "${GREEN}=== Powerlevel10k Installation Menu ===${NC}"
    echo -e "Platform detected: ${YELLOW}$PLATFORM${NC}"
    echo ""
    echo "Select installation method:"
    echo "1) Oh My Zsh (Recommended for beginners)"
    echo "2) Antigen (Fast and lightweight)"
    echo "3) Manual (Advanced users)"
    echo "4) Exit"
    echo ""
    
    read -p "Enter your choice [1-4]: " method_choice
    
    case $method_choice in
        1) install_method="oh-my-zsh" ;;
        2) install_method="antigen" ;;
        3) install_method="manual" ;;
        4) exit 0 ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
    
    echo ""
    read -p "Install Nerd Font automatically? (y/n): " font_choice
    case $font_choice in
        [Yy]*) install_font="yes" ;;
        *) install_font="no" ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Summary:${NC}"
    echo -e "Method: ${GREEN}$install_method${NC}"
    echo -e "Install Font: ${GREEN}$install_font${NC}"
    echo -e "Platform: ${GREEN}$PLATFORM${NC}"
    echo ""
    
    read -p "Proceed with installation? (y/n): " confirm
    case $confirm in
        [Yy]*) main_installation "$install_method" "$install_font" ;;
        *) echo "Installation cancelled"; exit 0 ;;
    esac
}

# Check if running with sudo/root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root/sudo"
    exit 1
fi

# Start the interactive menu
show_menu 
