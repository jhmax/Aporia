# Android-first checklist — Aporia

- [ ] Install stable Flutter and Android Studio.
- [ ] Generate platform folders with `bash scripts/bootstrap_platforms.sh`.
- [ ] `flutter pub get` finishes without errors.
- [ ] `flutter analyze` reports no errors.
- [ ] For a new Supabase project only, review and run `supabase/entrelinhas_schema.sql`.
- [ ] Test sign-up, email confirmation, sign-in and password recovery.
- [ ] Test creating reflections, reactions, saved reflections and reports.
- [ ] Open Android and Web clients on different devices and verify that they see the same reflections and reaction counts.
- [ ] Test empty states, network loss, timeouts and connection recovery.
- [ ] Test the Aporia midnight/indigo/gold palette across Explore, Write, Saved and Profile.
- [ ] Implement and test account deletion before public release.
- [ ] Add a privacy policy, terms and support contact.
- [ ] Test the release APK on at least two physical Android devices.
