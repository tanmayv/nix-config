{
  programs.git = {
    enable = true;
    config = {
      user.name = "Tanmay Vijayvargiya";
      user.email = "12tanmayvijay@gmail.com";
      user.signkey = "15EE62E8D21043C2";
      init.defaultBranch = "main";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
    lfs.enable = true;
  };

}
