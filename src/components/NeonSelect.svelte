<script>
    import { MorphIcon } from "morphicons/svelte";
    import { ChevronDown, CircleCheck } from "lucide";

    /** @typedef {{ value: string, label: string }} NeonOption */

    /** @type {{ options: NeonOption[], value: string, id?: string, placeholder?: string, disabled?: boolean }} */
    let {
        options = [],
        value = $bindable(""),
        id = "",
        placeholder = "Select…",
        disabled = false,
    } = $props();

    let open = $state(false);
    let highlighted = $state(0);

    /** @type {HTMLButtonElement | null} */
    let trigger;
    /** @type {HTMLDivElement | null} */
    let panel;

    function currentLabel() {
        const found = options.find((o) => o.value === value);
        return found ? found.label : placeholder;
    }

    function openList() {
        if (disabled) return;
        const idx = options.findIndex((o) => o.value === value);
        highlighted = idx >= 0 ? idx : 0;
        open = true;
    }

    function toggle() {
        if (disabled) return;
        if (open) {
            open = false;
        } else {
            openList();
        }
    }

    /** @param {NeonOption} opt */
    function choose(opt) {
        value = opt.value;
        open = false;
        trigger?.focus();
    }

    /** @param {KeyboardEvent} e */
    function onKeydown(e) {
        if (disabled) return;
        if (!open) {
            if (e.key === "Enter" || e.key === " " || e.key === "ArrowDown") {
                e.preventDefault();
                openList();
            }
            return;
        }
        if (e.key === "Escape") {
            e.preventDefault();
            open = false;
            trigger?.focus();
            return;
        }
        if (e.key === "ArrowDown") {
            e.preventDefault();
            highlighted = (highlighted + 1) % options.length;
            return;
        }
        if (e.key === "ArrowUp") {
            e.preventDefault();
            highlighted = (highlighted - 1 + options.length) % options.length;
            return;
        }
        if (e.key === "Home") {
            e.preventDefault();
            highlighted = 0;
            return;
        }
        if (e.key === "End") {
            e.preventDefault();
            highlighted = options.length - 1;
            return;
        }
        if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            if (options.length > 0) choose(options[highlighted]);
            return;
        }
        if (e.key === "Tab") {
            open = false;
        }
    }

    // Close when clicking outside the dropdown
    $effect(() => {
        if (!open) return;
        /** @param {PointerEvent} e */
        function onDocPointerDown(e) {
            const target = /** @type {Node} */ (e.target);
            if (
                panel &&
                !panel.contains(target) &&
                trigger &&
                !trigger.contains(target)
            ) {
                open = false;
            }
        }
        document.addEventListener("pointerdown", onDocPointerDown);
        return () =>
            document.removeEventListener("pointerdown", onDocPointerDown);
    });
</script>

<div class="neon-select" bind:this={panel}>
    <button
        type="button"
        bind:this={trigger}
        {id}
        class="neon-select-trigger"
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-controls={id ? `${id}-listbox` : undefined}
        onclick={toggle}
        onkeydown={onKeydown}
        {disabled}
    >
        <span class="neon-select-value">{currentLabel()}</span>
        <MorphIcon
            icon={ChevronDown}
            class={open ? "rotate-180" : ""}
            aria-hidden="true"
        />
    </button>

    {#if open}
        <ul
            id={id ? `${id}-listbox` : undefined}
            class="neon-select-list"
            role="listbox"
            tabindex="-1"
            aria-activedescendant={id
                ? `${id}-option-${highlighted}`
                : undefined}
        >
            {#each options as opt, i}
                <li
                    id={id ? `${id}-option-${i}` : undefined}
                    role="option"
                    aria-selected={opt.value === value}
                    class="neon-select-option"
                    class:neon-select-option-active={i === highlighted}
                    class:neon-select-option-selected={opt.value === value}
                    onclick={() => choose(opt)}
                    onmouseenter={() => (highlighted = i)}
                    onkeydown={(e) => {
                        if (e.key === "Enter" || e.key === " ") {
                            e.preventDefault();
                            choose(opt);
                        }
                    }}
                >
                    {#if opt.value === value}
                        <MorphIcon
                            icon={CircleCheck}
                            class="h-4 w-4"
                            aria-hidden="true"
                        />
                    {/if}
                    {opt.label}
                </li>
            {/each}
        </ul>
    {/if}
</div>
