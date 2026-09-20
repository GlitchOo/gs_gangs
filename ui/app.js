(() => {
	const app = document.getElementById('app');
	const gangLabel = document.getElementById('gangLabel');
	const balanceLine = document.getElementById('balanceLine');
	const nav = document.getElementById('nav');
	const sectionTitle = document.getElementById('sectionTitle');
	const sectionDesc = document.getElementById('sectionDesc');
	const pageBody = document.getElementById('pageBody');
	const btnClose = document.getElementById('btnClose');
	const btnBack = document.getElementById('btnBack');

	/** @type {any} */
	let state = null;
	/** @type {string} */
	let page = 'balance';
	/** @type {any} */
	let selectedMember = null;

	const NAV = [
		{ id: 'balance', titleKey: 'ledger_balance', pages: ['balance'] },
		{ id: 'ledger', titleKey: 'manage_ledger', pages: ['ledger', 'deposit', 'withdraw'] },
		{ id: 'gang', titleKey: 'manage_gang', pages: ['gang', 'members', 'member', 'invite'] },
		{ id: 'wars', titleKey: 'wars', pages: ['wars'] },
	];

	const PAGE_META = {
		balance: { titleKey: 'ledger_balance', descKey: 'ledger_balance_desc' },
		ledger: { titleKey: 'manage_ledger', descKey: 'manage_ledger_pick' },
		deposit: { titleKey: 'deposit', descKey: 'deposit_desc' },
		withdraw: { titleKey: 'withdraw', descKey: 'withdraw_desc' },
		gang: { titleKey: 'manage_gang', descKey: 'manage_gang_pick' },
		members: { titleKey: 'members', descKey: 'members_desc' },
		member: { titleKey: 'manage', descKey: 'member_ranks_desc' },
		invite: { titleKey: 'invite', descKey: 'invite_desc' },
		wars: { titleKey: 'wars', descKey: 'wars_desc' },
	};

	const PARENT = {
		deposit: 'ledger',
		withdraw: 'ledger',
		members: 'gang',
		member: 'members',
		invite: 'gang',
	};

	function t(key, ...args) {
		const locale = state?.locale || {};
		let str = locale[key] || key;
		for (let i = 0; i < args.length; i++) {
			str = str.replace('%s', String(args[i]));
		}
		return str;
	}

	function money(n) {
		const v = Number(n) || 0;
		return `$${v.toLocaleString('en-US')}`;
	}

	function post(name, data) {
		const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'gs_gangs';
		return fetch(`https://${resource}/${name}`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json; charset=UTF-8' },
			body: JSON.stringify(data || {}),
		}).catch(() => {});
	}

	function setOpen(open) {
		app.classList.toggle('hidden', !open);
	}

	function go(next) {
		page = next;
		if (next !== 'member') selectedMember = null;
		render();
	}

	function activeNavId() {
		for (const item of NAV) {
			if (item.pages.includes(page)) return item.id;
		}
		return 'balance';
	}

	function renderNav() {
		nav.innerHTML = '';
		const active = activeNavId();
		for (const item of NAV) {
			const btn = document.createElement('button');
			btn.type = 'button';
			btn.className = 'nav-item' + (active === item.id ? ' active' : '');
			btn.textContent = t(item.titleKey);
			btn.addEventListener('click', () => {
				if (item.id === 'balance') go('balance');
				else if (item.id === 'ledger') go('ledger');
				else if (item.id === 'gang') go('gang');
				else if (item.id === 'wars') go('wars');
			});
			nav.appendChild(btn);
		}
	}

	function clearBody() {
		pageBody.innerHTML = '';
	}

	function addChoice(label, desc, onClick) {
		const btn = document.createElement('button');
		btn.type = 'button';
		btn.className = 'choice-item';
		btn.innerHTML = `<span class="choice-title">${label}</span><span class="choice-desc">${desc}</span>`;
		btn.addEventListener('click', onClick);
		pageBody.appendChild(btn);
	}

	function formatLogTime(unix) {
		const ts = Number(unix) || 0;
		if (!ts) return '';
		const d = new Date(ts * 1000);
		const mm = String(d.getMonth() + 1).padStart(2, '0');
		const dd = String(d.getDate()).padStart(2, '0');
		const hh = String(d.getHours()).padStart(2, '0');
		const mi = String(d.getMinutes()).padStart(2, '0');
		return `${mm}/${dd} ${hh}:${mi}`;
	}

	function renderBalance() {
		clearBody();

		const hero = document.createElement('div');
		hero.className = 'balance-hero';
		hero.innerHTML = `
			<div class="amount">${money(state.balance)}</div>
			<p class="hint">${t('ledger_balance_hint')}</p>
		`;
		pageBody.appendChild(hero);

		const logTitle = document.createElement('p');
		logTitle.className = 'log-title';
		logTitle.textContent = t('ledger_log');
		pageBody.appendChild(logTitle);

		const log = state.log || [];
		const list = document.createElement('div');
		list.className = 'ledger-log';

		if (log.length === 0) {
			list.innerHTML = `<p class="empty">${t('ledger_log_empty')}</p>`;
		} else {
			for (const entry of log) {
				const row = document.createElement('div');
				row.className = 'ledger-log-item ' + (entry.type === 'withdraw' ? 'withdraw' : 'deposit');
				const label = entry.type === 'withdraw'
					? t('ledger_log_withdraw', money(entry.amount), entry.player || '')
					: t('ledger_log_deposit', money(entry.amount), entry.player || '');
				row.innerHTML = `
					<span class="log-main">${label}</span>
					<span class="log-time">${formatLogTime(entry.at)}</span>
				`;
				list.appendChild(row);
			}
		}

		pageBody.appendChild(list);
	}

	function renderLedgerHub() {
		clearBody();
		const canDeposit = !!state.perms?.deposit;
		const canWithdraw = !!state.perms?.withdraw;

		if (!canDeposit && !canWithdraw) {
			pageBody.innerHTML = `<p class="empty">${t('no_permission')}</p>`;
			return;
		}

		if (canDeposit) {
			addChoice(t('deposit'), t('deposit_desc'), () => go('deposit'));
		}
		if (canWithdraw) {
			addChoice(t('withdraw'), t('withdraw_desc'), () => go('withdraw'));
		}
	}

	function renderAmountForm(kind) {
		clearBody();
		const row = document.createElement('div');
		row.className = 'form-row';
		row.innerHTML = `<label>${t('amount')}</label>`;

		const stepper = document.createElement('div');
		stepper.className = 'amount-stepper';

		const input = document.createElement('input');
		input.type = 'number';
		input.min = '1';
		input.step = '1';
		input.placeholder = '0';
		input.className = 'amount-input';
		input.autofocus = true;

		const steppers = document.createElement('div');
		steppers.className = 'amount-spinners';

		const btnUp = document.createElement('button');
		btnUp.type = 'button';
		btnUp.className = 'amount-spin';
		btnUp.setAttribute('aria-label', 'Increase');
		btnUp.innerHTML = '<span aria-hidden="true">▲</span>';

		const btnDown = document.createElement('button');
		btnDown.type = 'button';
		btnDown.className = 'amount-spin';
		btnDown.setAttribute('aria-label', 'Decrease');
		btnDown.innerHTML = '<span aria-hidden="true">▼</span>';

		const nudge = (dir) => {
			const cur = Math.floor(Number(input.value) || 0);
			const next = Math.max(1, cur + dir);
			input.value = String(next);
			input.dispatchEvent(new Event('input', { bubbles: true }));
		};

		btnUp.addEventListener('click', () => nudge(1));
		btnDown.addEventListener('click', () => nudge(-1));

		steppers.appendChild(btnUp);
		steppers.appendChild(btnDown);
		stepper.appendChild(input);
		stepper.appendChild(steppers);
		row.appendChild(stepper);

		const actions = document.createElement('div');
		actions.className = 'actions';
		const btn = document.createElement('button');
		btn.type = 'button';
		btn.className = 'ink-btn primary';
		btn.textContent = t(kind);
		btn.addEventListener('click', () => {
			const amount = Math.floor(Number(input.value) || 0);
			if (amount < 1) return;
			post(kind, { amount });
			input.value = '';
		});
		actions.appendChild(btn);
		row.appendChild(actions);
		pageBody.appendChild(row);

		const note = document.createElement('p');
		note.className = 'empty';
		note.textContent = t('ledger_balance_line', money(state.balance));
		pageBody.appendChild(note);
	}

	function renderGangHub() {
		clearBody();
		addChoice(t('members'), t('members_desc'), () => go('members'));
		addChoice(t('invite'), t('invite_desc'), () => go('invite'));
	}

	function renderMembers() {
		clearBody();
		const list = document.createElement('div');
		list.className = 'list';

		const members = state.members || [];
		if (members.length === 0) {
			list.innerHTML = `<p class="empty">${t('members_empty')}</p>`;
		}

		for (const member of members) {
			const row = document.createElement('div');
			row.className = 'list-item';
			row.innerHTML = `
				<div class="meta">
					<div class="title">${member.firstname} ${member.lastname}</div>
					<div class="sub">${member.rankLabel || ''}</div>
				</div>
			`;
			const actions = document.createElement('div');
			actions.className = 'row-actions';
			const manage = document.createElement('button');
			manage.type = 'button';
			manage.className = 'ink-btn';
			manage.textContent = t('manage');
			manage.addEventListener('click', () => {
				selectedMember = member;
				go('member');
			});
			actions.appendChild(manage);
			row.appendChild(actions);
			list.appendChild(row);
		}

		pageBody.appendChild(list);
	}

	function renderMemberDetail() {
		const member = selectedMember;
		if (!member) {
			go('members');
			return;
		}

		clearBody();
		const wrap = document.createElement('div');
		wrap.className = 'member-detail';

		const ranks = document.createElement('div');
		ranks.className = 'rank-list';

		const rankTitle = document.createElement('p');
		rankTitle.className = 'log-title';
		rankTitle.textContent = t('change_rank');
		ranks.appendChild(rankTitle);

		for (const rank of state.ranks || []) {
			const isCurrent = rank.id === member.rank;
			const btn = document.createElement('button');
			btn.type = 'button';
			btn.className = 'rank-option' + (isCurrent ? ' active' : '');
			btn.innerHTML = `
				<span class="rank-option-label">${rank.label}</span>
				${isCurrent ? '<span class="rank-stamp" title="Current"></span>' : '<span class="rank-option-mark"></span>'}
			`;
			btn.addEventListener('click', () => {
				if (isCurrent) return;
				post('changeRank', { charidentifier: member.charidentifier, rank: rank.id });
				selectedMember = { ...member, rank: rank.id, rankLabel: rank.label };
				render();
			});
			ranks.appendChild(btn);
		}
		wrap.appendChild(ranks);

		const kick = document.createElement('button');
		kick.type = 'button';
		kick.className = 'ink-btn danger kick-btn';
		kick.textContent = t('kick_member');
		kick.addEventListener('click', () => {
			post('kickMember', { charidentifier: member.charidentifier });
			selectedMember = null;
			go('members');
		});
		wrap.appendChild(kick);

		pageBody.appendChild(wrap);
	}

	function renderInvite() {
		clearBody();
		const nearby = state.nearby || [];
		const list = document.createElement('div');
		list.className = 'list';

		if (nearby.length === 0) {
			list.innerHTML = `<p class="empty">${t('invite_none_nearby')}</p>`;
		} else {
			for (const player of nearby) {
				const row = document.createElement('div');
				row.className = 'list-item';
				row.innerHTML = `
					<div class="meta">
						<div class="title">${player.name}</div>
						<div class="sub">${player.inGang ? t('invite_already_in_gang', player.name) : t('invite_player_desc', player.name, player.dist)}</div>
					</div>
				`;
				if (!player.inGang) {
					const actions = document.createElement('div');
					actions.className = 'row-actions';
					const btn = document.createElement('button');
					btn.type = 'button';
					btn.className = 'ink-btn primary';
					btn.textContent = t('invite');
					btn.addEventListener('click', () => post('invite', { serverId: player.serverId }));
					actions.appendChild(btn);
					row.appendChild(actions);
				}
				list.appendChild(row);
			}
		}

		pageBody.appendChild(list);
	}

	function renderWars() {
		clearBody();
		const list = document.createElement('div');
		list.className = 'list';

		const gangs = state.warsGangs || [];
		if (gangs.length === 0) {
			list.innerHTML = `<p class="empty">${t('no_wars')}</p>`;
			pageBody.appendChild(list);
			return;
		}

		for (const gang of gangs) {
			const row = document.createElement('div');
			row.className = 'list-item';
			const badge = gang.atWar
				? `<span class="badge war">${t('at_war')}</span>`
				: `<span class="badge peace">${t('at_peace')}</span>`;
			row.innerHTML = `
				<div class="meta">
					<div class="title">${gang.label}</div>
					<div class="sub">${badge}${gang.timer ? ' · ' + gang.timer : ''}</div>
				</div>
			`;
			const actions = document.createElement('div');
			actions.className = 'row-actions';
			const btn = document.createElement('button');
			btn.type = 'button';
			btn.className = 'ink-btn' + (gang.atWar ? '' : ' danger');
			btn.textContent = gang.atWar ? t('declare_peace') : t('declare_war');
			btn.addEventListener('click', () => {
				post(gang.atWar ? 'declarePeace' : 'declareWar', { gang: gang.name });
			});
			actions.appendChild(btn);
			row.appendChild(actions);
			list.appendChild(row);
		}

		pageBody.appendChild(list);
	}

	function renderRightPage() {
		const meta = PAGE_META[page] || PAGE_META.balance;
		sectionTitle.textContent = page === 'member' && selectedMember
			? `${selectedMember.firstname} ${selectedMember.lastname}`
			: t(meta.titleKey);
		sectionDesc.textContent = page === 'member' && selectedMember
			? t('member_subtext', selectedMember.rankLabel || '')
			: t(meta.descKey);

		const canBack = !!PARENT[page];
		btnBack.classList.toggle('hidden', !canBack);
		btnBack.textContent = t('back');

		if (page === 'balance') renderBalance();
		else if (page === 'ledger') renderLedgerHub();
		else if (page === 'deposit') renderAmountForm('deposit');
		else if (page === 'withdraw') renderAmountForm('withdraw');
		else if (page === 'gang') renderGangHub();
		else if (page === 'members') renderMembers();
		else if (page === 'member') renderMemberDetail();
		else if (page === 'invite') renderInvite();
		else if (page === 'wars') renderWars();
	}

	function render() {
		if (!state) return;

		gangLabel.textContent = state.gangLabel || '';
		balanceLine.textContent = t('ledger_balance_line', money(state.balance));
		btnClose.textContent = t('close');

		renderNav();
		renderRightPage();
	}

	btnClose.addEventListener('click', () => post('close'));
	btnBack.addEventListener('click', () => {
		const parent = PARENT[page];
		if (parent) go(parent);
	});

	window.addEventListener('keydown', (e) => {
		if (e.key === 'Escape') {
			if (PARENT[page]) go(PARENT[page]);
			else post('close');
		}
	});

	window.addEventListener('message', (event) => {
		const data = event.data;
		if (!data || !data.action) return;

		if (data.action === 'open') {
			state = data.payload || {};
			page = data.payload?.section || 'balance';
			selectedMember = null;
			setOpen(true);
			render();
		} else if (data.action === 'update') {
			state = { ...(state || {}), ...(data.payload || {}) };
			if (page === 'member' && selectedMember) {
				const found = (state.members || []).find(
					(m) => String(m.charidentifier) === String(selectedMember.charidentifier)
				);
				if (found) selectedMember = found;
			}
			render();
		} else if (data.action === 'close') {
			setOpen(false);
			state = null;
		}
	});
})();
