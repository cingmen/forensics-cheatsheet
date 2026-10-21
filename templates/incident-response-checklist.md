# Incident Response Checklist / Checklist Response Insiden

## Phase 1: Preparation (Pre-incident) / Fase Persiapan

- [ ] IR team dikonfirmasi dengan kontak 24/7
- [ ] Forensic toolkit tersedia (write-blocker, FTK Imager, Volatility, dll)
- [ ] Evidence locker & chain of custody forms siap
- [ ] Backup imaging device tersedia
- [ ] External storage untuk evidence (terpisah dari produksi)
- [ ] Communication plan (out-of-band channel)

## Phase 2: Identification / Fase Identifikasi

- [ ] Confirm incident (verifikasi alert, false positive check)
- [ ] Document initial report (siapa, apa, kapan, dimana)
- [ ] Activate IR team
- [ ] Initial scope: host terdampak, user terdampak
- [ ] Start incident log & timeline

## Phase 3: Containment / Fase Penahanan

### Short-term containment
- [ ] Isolate affected hosts (network isolation, jangan shutdown)
- [ ] Disable compromised accounts
- [ ] Block C2 IPs / domains di firewall
- [ ] Preserve volatile data (memory dump)

### Long-term containment
- [ ] Remove malware (verified clean)
- [ ] Patch vulnerability yang dieksploitasi
- [ ] Reset semua credentials yang berpotensi terkompromi

## Phase 4: Eradication / Fase Pemberantasan

- [ ] Identify root cause (vulnerability, misconfiguration, phishing)
- [ ] Remove malicious artifacts
- [ ] Validate eradication (re-scan, re-image if necessary)

## Phase 5: Recovery / Fase Pemulihan

- [ ] Restore from clean backup (preferred) OR rebuild from known-good
- [ ] Validate restored system (functional testing, security testing)
- [ ] Phased reconnection to network
- [ ] Enhanced monitoring selama X hari

## Phase 6: Lessons Learned / Fase Pembelajaran

- [ ] Post-incident review meeting (scheduled within 2 weeks)
- [ ] Document timeline, findings, gaps
- [ ] Update IR playbook
- [ ] Update detection rules
- [ ] Share lessons (anonymized) ke tim yang lebih luas

## Phase 7: Forensic Documentation (ongoing) / Fase Dokumentasi Forensik

- [ ] All evidence properly labeled with Evidence ID
- [ ] Chain of custody form completed for each item
- [ ] Hash verification documented
- [ ] All actions logged with timestamp + investigator name
- [ ] Final forensic report drafted

---

**Form Version**: v1.0 · **Repository**: cingmen/forensics-cheatsheet · **License**: CC-BY-4.0
