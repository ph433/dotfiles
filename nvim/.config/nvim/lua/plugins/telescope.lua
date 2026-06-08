return {
    'nvim-telescope/telescope.nvim',
    version = '*', -- Sử dụng phiên bản ổn định mới nhất theo tài liệu
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- Bộ tăng tốc Sorter bằng ngôn ngữ C (bắt buộc phải có 'make' trong máy)
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        -- Thêm icon cho đẹp mắt nếu bạn dùng Nerd Fonts
        'nvim-tree/nvim-web-devicons', 
    },
    config = function()
        local telescope = require('telescope')
        
        telescope.setup({
          defaults = {
            -- Thêm cấu hình giao diện mặc định của bạn ở đây nếu muốn
            prompt_prefix = " 🔍 ",
            selection_caret = "  ",
          },
          pickers = {
            find_files = {
              theme = "dropdown", -- Biến cửa sổ tìm file thành dạng popup thả từ trên xuống giống dmenu
            }
          },
          extensions = {
            fzf = {
              fuzzy = true,                    -- Bật tìm kiếm mờ
              override_generic_sorter = true,  -- Ghi đè bộ lọc mặc định
              override_file_sorter = true,     -- Ghi đè bộ lọc file
              case_mode = "smart_case",        -- Tự động nhận diện chữ hoa/thường
            }
          }
        })

        -- Bắt buộc phải có dòng này để kích hoạt bộ tăng tốc FZF bằng C ghen
        telescope.load_extension('fzf')

        -- ⌨️ Cài đặt phím tắt (Keymaps) chuẩn công thái học để gọi nhanh
        local builtin = require('telescope.builtin')
        
        -- Nhấn Space + f + f để tìm file trong dự án (nhanh như chớp)
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope tìm file' })
        
        -- Nhấn Space + f + g để tìm một chuỗi chữ bất kỳ trong toàn bộ code (Live Grep)
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
        
        -- Nhấn Space + f + b để xem danh sách các tab/buffer đang mở
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope xem buffers' })
        
        -- Nhấn Space + f + h để tra cứu nhanh tài liệu Help cứu bồ của Neovim
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope tra cứu Help' })
    end
}
