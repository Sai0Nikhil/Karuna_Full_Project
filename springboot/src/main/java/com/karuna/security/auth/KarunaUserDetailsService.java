package com.karuna.security.auth;

import java.util.Collection;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.karuna.entity.User;
import com.karuna.entity.enums.UserRole;
import com.karuna.repository.UserRepository;

@Service
public class KarunaUserDetailsService implements UserDetailsService {

	private final UserRepository userRepository;

	public KarunaUserDetailsService(UserRepository userRepository) {
		this.userRepository = userRepository;
	}

	@Override
	public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
		User user = userRepository.findByEmail(email)
				.orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));

		Collection<GrantedAuthority> authorities = buildAuthorities(user);

		return new KarunaUserDetails(user, authorities);
	}

	private Collection<GrantedAuthority> buildAuthorities(User user) {
		String role = user.getRole();
		UserRole userRole;
		try {
			userRole = UserRole.valueOf(role == null ? "CITIZEN" : role.toUpperCase());
		} catch (IllegalArgumentException ex) {
			userRole = UserRole.CITIZEN;
		}
		return java.util.List.of(new SimpleGrantedAuthority("ROLE_" + userRole.name()));
	}
}

