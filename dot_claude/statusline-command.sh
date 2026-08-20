#!/usr/bin/env bash
# Status line: model name + context usage progress bar + token count.
# Reads the JSON Claude Code sends on stdin and prints a single line.
# Uses jq if available (fast path); falls back to node (Claude Code always
# has node, since Claude Code itself is a Node app) if jq isn't installed.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  read -r model used input_tokens output_tokens effort thinking five_hour <<< "$(jq -r '
    (.model.display_name // .model.id // "Claude" | gsub(" "; "_")) as $model
    | (.context_window // {}) as $cw
    | (.effort.level // "none") as $effort
    | (if .thinking.enabled then "on" else "off" end) as $thinking
    | (.rate_limits.five_hour.used_percentage // "none") as $fiveHour
    | "\($model) \($cw.used_percentage // 0) \($cw.total_input_tokens // 0) \($cw.total_output_tokens // 0) \($effort) \($thinking) \($fiveHour)"
  ' <<< "$input")"
else
  read -r model used input_tokens output_tokens effort thinking five_hour <<< "$(node -e '
    let data = "";
    process.stdin.on("data", d => data += d);
    process.stdin.on("end", () => {
      let j = {};
      try { j = JSON.parse(data); } catch (e) {}
      const model = (j.model && (j.model.display_name || j.model.id)) || "Claude";
      const cw = j.context_window || {};
      const used = cw.used_percentage ?? 0;
      const inTok = cw.total_input_tokens ?? 0;
      const outTok = cw.total_output_tokens ?? 0;
      const effort = (j.effort && j.effort.level) || "none";
      const thinking = (j.thinking && j.thinking.enabled) ? "on" : "off";
      const fiveHour = (j.rate_limits && j.rate_limits.five_hour && j.rate_limits.five_hour.used_percentage != null)
        ? j.rate_limits.five_hour.used_percentage
        : "none";
      console.log(`${model.replace(/ /g, "_")} ${used} ${inTok} ${outTok} ${effort} ${thinking} ${fiveHour}`);
    });
  ' <<< "$input")"
fi

model=$(echo "$model" | tr '_' ' ')

# Round to a whole number for display and bar math.
used_int=$(printf '%.0f' "$used" 2>/dev/null || echo 0)

# Build a 10-segment bar. Each segment is 10%.
bar_width=10
filled=$(( used_int / 10 ))
if [ "$filled" -gt "$bar_width" ]; then filled=$bar_width; fi
empty=$(( bar_width - filled ))

bar=""
i=0
while [ "$i" -lt "$filled" ]; do bar="${bar}#"; i=$((i+1)); done
i=0
while [ "$i" -lt "$empty" ]; do bar="${bar}-"; i=$((i+1)); done

# Colour the bar: green under 60%, yellow under 85%, red above.
if [ "$used_int" -ge 85 ]; then
  colour="\033[31m"   # red
elif [ "$used_int" -ge 60 ]; then
  colour="\033[33m"   # yellow
else
  colour="\033[32m"   # green
fi
reset="\033[0m"
dim="\033[2m"

total_tokens=$(( input_tokens + output_tokens ))
if [ "$total_tokens" -ge 1000 ]; then
  tokens_display="$(( total_tokens / 1000 ))k"
else
  tokens_display="${total_tokens}"
fi

# Build the effort/thinking suffix. Skip effort entirely if the model doesn't support it.
extra=""
if [ "$effort" != "none" ]; then
  extra="${dim}${effort}${reset}"
fi
if [ "$thinking" = "on" ]; then
  if [ -n "$extra" ]; then
    extra="${extra} ${dim}+think${reset}"
  else
    extra="${dim}think${reset}"
  fi
fi
if [ -n "$extra" ]; then
  extra=" ${dim}·${reset} ${extra}"
fi

# 5-hour session limit, when Claude Code provides it (subscription plans only).
five_hour_display=""
if [ "$five_hour" != "none" ]; then
  five_hour_int=$(printf '%.0f' "$five_hour" 2>/dev/null || echo 0)
  if [ "$five_hour_int" -ge 85 ]; then
    fh_colour="\033[31m"   # red
  elif [ "$five_hour_int" -ge 60 ]; then
    fh_colour="\033[33m"   # yellow
  else
    fh_colour="\033[32m"   # green
  fi
  five_hour_display=" ${dim}·${reset} ${dim}5h:${reset}${fh_colour}${five_hour_int}%${reset}"
fi

printf "${dim}%s${reset}  ${colour}[%s]${reset} ${dim}%s%%${reset} ${dim}(%s tok)${reset}${extra}%b\n" "$model" "$bar" "$used_int" "$tokens_display" "$five_hour_display"
