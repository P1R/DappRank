<script>
    import { themes, currentTheme, setTheme } from "../lib/theme.svelte.js";
    import { MorphIcon } from "morphicons/svelte";
    import { Sparkles, Sun, Moon } from "lucide";

    const ICONS = {
        original: Sparkles,
        light: Sun,
        dark: Moon,
    };
    /** @type {Record<string, any>} */
    const ICON_MAP = ICONS;

    let open = $state(false);

    function toggle() {
        open = !open;
    }

    function choose(/** @type {string} */ id) {
        setTheme(id);
        open = false;
    }

    /** Close the menu when clicking outside the toggle. @param {MouseEvent} e */
    function handleDocClick(e) {
        const target = e.target;
        if (
            open &&
            (!(target instanceof Element) ||
                !target.closest("[data-theme-toggle]"))
        ) {
            open = false;
        }
    }

    $effect(() => {
        if (open) {
            document.addEventListener("click", handleDocClick);
            return () => document.removeEventListener("click", handleDocClick);
        }
    });
</script>

<div class="relative" data-theme-toggle>
    <button
        class="btn-icon"
        onclick={toggle}
        aria-expanded={open}
        aria-haspopup="true"
        aria-label="Change theme"
        title="Change theme"
    >
        <MorphIcon
            icon={ICON_MAP[currentTheme.id]}
            spring="snappy"
            reducedMotion="user"
            aria-hidden="true"
        />
    </button>

    {#if open}
        <div
            class="absolute right-0 top-full z-50 mt-2 w-44 overflow-hidden rounded-lg border border-neon-cyan/40 bg-void/95 p-1 shadow-xl backdrop-blur-md"
            role="menu"
            aria-label="Theme"
        >
            {#each themes as theme}
                <button
                    class="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm font-medium transition-colors duration-150 {theme.id ===
                    currentTheme.id
                        ? 'bg-neon-cyan/15 text-neon-cyan'
                        : 'text-ink/80 hover:bg-neon-cyan/10'}"
                    role="menuitemradio"
                    aria-checked={theme.id === currentTheme.id}
                    onclick={() => choose(theme.id)}
                >
                    <MorphIcon
                        icon={ICON_MAP[theme.id]}
                        class="h-4 w-4"
                        spring="snappy"
                        reducedMotion="user"
                        aria-hidden="true"
                    />
                    <span>{theme.label}</span>
                    {#if theme.id === currentTheme.id}
                        <span class="ml-auto" aria-hidden="true">✓</span>
                    {/if}
                </button>
            {/each}
        </div>
    {/if}
</div>
