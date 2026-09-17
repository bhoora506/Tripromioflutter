with open(r'd:\development\tripromio\lib\presentation\screens\profile\profile_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = lines[:1472] # keeping up to line 1472

tail = """                  InkWell(
                    onTap: onLogout,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: AppColors.error, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Log out',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.error, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
"""

with open(r'd:\development\tripromio\lib\presentation\screens\profile\profile_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
    f.write(tail)
