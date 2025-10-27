{
  programs.git = {
    enable = true;
    config = {
      user.name = "Tanmay Vijayvargiya";
      user.email = "12tanmayvijay@gmail.com";
      init.defaultBranch = "main";
    };
    lfs.enable = true;
  };

}
