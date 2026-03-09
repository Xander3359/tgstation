
// start of on_hit with args (firer, src, target)
// #define COMSIG_HOOK_ "hook_begin"
// 	#define COMPONENT_CANCEL_PULL (1<<0)

// (firer, target), called when /datum/hook_and_move finishes it's movement, either by successfully moving the victim to the destination or by being destroyed by other means. Called on the firer of the hook, with the target as an argument.
#define COMSIG_HOOK_FINISH "hook_finish"
